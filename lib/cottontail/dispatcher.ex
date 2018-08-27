defmodule Cottontail.Dispatcher do
  @moduledoc false

  defstruct [
    :broker_pid,
    :worker,
    pool_size: 1,
    pool_overflow: 5
  ]

  use GenServer

  alias Cottontail.Worker
  alias :poolboy, as: PB

  def start_link(spec) do
    GenServer.start_link(__MODULE__, spec)
  end

  def init(spec) do
    send self(), :start_pool

    {:ok, spec}
  end

  def handle_info(:start_pool, %{worker: worker_spec} = spec) do
    pool_name = generate_pool_name(worker_spec)

    pool_options = [
      {:name, {:local, pool_name}},
      {:worker_module, Worker},
      {:size, spec.pool_size},
      {:max_overflow, spec.pool_overflow}
    ]

    {:ok, _} = PB.start_link(pool_options, worker_spec)

    {:noreply, Map.put(spec, :pool_name, pool_name)}
  end
  def handle_info({:dispatch, msg, meta}, spec) do
    tag = meta.delivery_tag

    result = PB.transaction(spec.pool_name, fn pid ->
      pid
      |> Worker.handle_deliver(msg, meta)
      |> case do
        :ok           -> {:consume_ok, tag}
        {:error, err} -> {:consume_error, err, tag}
      end
    end)

    send spec.broker_pid, result

    {:noreply, spec}
  end

  defp generate_pool_name(fun) do
    quoted = quote do
      unquote(fun)
    end

    quoted
    |> Macro.to_string()
    |> sha()
    |> Base.encode16(case: :lower)
    |> String.to_atom()
  end

  defp sha(str) do
    :crypto.hash(:sha, str)
  end
end
