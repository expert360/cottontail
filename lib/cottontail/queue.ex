defmodule Cottontail.Queue do
  @moduledoc false
  use GenServer

  require Logger

  defstruct [
    :broker_pid,
    :url,
    :exchange,
    :routing_key,
    consumer: false,
    durable: true,
    dlx_exchange: :auto,
    dlx_routing_key: :auto
  ]

  @adapter Application.get_env(:cottontail, :adapter, AMQP)

  def start_link(spec) do
    Process.flag(:trap_exit, true)

    GenServer.start_link(__MODULE__, spec)
  end

  def init(spec) do
    send self(), :connect
    {:ok, spec}
  end

  def publish(pid, msg) do
    GenServer.call(pid, {:publish, msg})
  end

  def handle_call({:publish, msg}, _, spec) do
    {ex_name, _} = spec.exchange

    result = @adapter.Basic.publish(spec.channel, ex_name, spec.routing_key, msg, persistent: true)

    Logger.debug fn ->
      "Publishing #{inspect(msg)} to #{inspect(spec)}: #{inspect(result)}"
    end

    {:reply, result, spec}
  end

  def handle_info(:connect, spec) do
    {:ok, chan} = connect(spec)

    {:noreply, Map.put(spec, :channel, chan)}
  end
  def handle_info({:publish, msg}, spec) do
    publish(self(), msg)

    {:noreply, spec}
  end
  def handle_info({:ack, _}, spec) do
    {:noreply, spec}
  end
  def handle_info({:DOWN, _, :process, _pid, _reason}, spec) do
    send self(), :connect

    {:noreply, spec}
  end

  defp connect(spec) do
    {ex_name, ex_type} = spec.exchange

    dlx_ex = get_dlx_exchange(spec)
    dlx_rk = get_dlx_routing_key(spec)

    with {:ok, conn} <- @adapter.Connection.open(spec.url),
    {:ok, chan} <- @adapter.Channel.open(conn),
    {:ok, _} <- @adapter.Queue.declare(chan, dlx_rk, durable: spec.durable),
    {:ok, _} <-
      @adapter.Queue.declare(
        chan,
        spec.routing_key,
        durable: spec.durable,
        arguments: [
          {"x-dead-letter-exchange", :longstr, dlx_ex},
          {"X-dead-letter-routing-key", :longstr, dlx_rk}
        ]
      ),
    :ok <- apply(@adapter.Exchange, ex_type, [chan, ex_name, [durable: spec.durable]]),
    :ok <- @adapter.Queue.bind(chan, spec.routing_key, ex_name, routing_key: spec.routing_key),
    {:ok, _} <- maybe_consume(chan, spec) do
      Logger.info("Queue client started: #{spec.routing_key}")

      {:ok, chan}
    else
    _ ->
      Logger.warn("Connection failed for #{inspect(spec)}")
      Process.sleep(1_000)
      connect(spec)
    end
  end

  defp get_dlx_exchange(%{dlx_exchange: :auto}), do: ""
  defp get_dlx_exchange(%{dlx_exchange: ex}), do: ex

  defp get_dlx_routing_key(%{routing_key: rk, dlx_routing_key: :auto}) do
    "#{rk}.dlx"
  end

  defp get_dlx_routing_key(%{dlx_routing_key: rk}), do: rk

  defp maybe_consume(chan, %{consumer: true} = spec) do
    @adapter.Basic.consume(chan, spec.routing_key, spec.broker_pid)
  end
  defp maybe_consume(_, _) do
    {:ok, nil}
  end
end
