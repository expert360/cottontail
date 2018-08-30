defmodule Cottontail do
  @moduledoc """
  Documentation for Cottontail.
  """

  defstruct [
    :description,
    :queue,
    :dispatcher
  ]

  alias Cottontail.{
    Broker,
    Dispatcher,
    Queue
  }

  @required [
    queue: [:url, :exchange, :routing_key],
    dispatcher: [:worker]
  ]

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)

      @before_compile unquote(__MODULE__)
    end
  end

  defmacro connection(desc, do: block) do
    quote do
      @description unquote(desc)

      unquote(block)
    end
  end

  defmacro queue(opts) do
    quote do
      @queue unquote(opts)
    end
  end

  defmacro dispatcher(opts) do
    quote do
      @dispatcher unquote(opts)
    end
  end

  defmacro __before_compile__(%{module: mod}) do
    cfg = process_config([
      description: Module.get_attribute(mod, :description),
      queue: Module.get_attribute(mod, :queue),
      dispatcher: Module.get_attribute(mod, :dispatcher)
    ])

    validate_config(cfg)

    quote do
      use GenServer

      @cottontail_spec %Cottontail{
        description: unquote(cfg[:description]),
        queue: struct(Queue, unquote(cfg[:queue])),
        dispatcher: struct(Dispatcher, unquote(cfg[:dispatcher]))
      }

      def start_link(_) do
        GenServer.start_link(__MODULE__, [], name: __MODULE__)
      end

      def init([]) do
        {:ok, queue_pid} = Queue.start_link(@cottontail_spec.queue)
        {:ok, dispatcher_pid} = Dispatcher.start_link(@cottontail_spec.dispatcher)

        Broker.start_link(%{
          queue_pid: queue_pid,
          dispatcher_pid: dispatcher_pid
        })
      end

      def publish(msg) do
        GenServer.call(__MODULE__, {:publish, msg})
      end

      def handle_call({:publish, msg}, _, broker_pid) do
        send broker_pid, {:publish, msg}

        {:reply, :ok, broker_pid}
      end
    end
  end

  defp process_config(cfg) do
    defaults = Application.get_env(:cottontail, :defaults, [])

    merge(defaults, cfg)
  end

  defp validate_config(cfg) do
    Enum.each(@required, fn {name, attrs} ->
      sub = Keyword.get(cfg, name, nil)

      if is_nil(sub) do
        raise ArgumentError, "Config is missing for: #{inspect(name)}"
      else
        Enum.each(attrs, fn attr ->
          if is_nil(Keyword.get(sub, attr, nil)) do
            raise ArgumentError, "Config is missing for: #{inspect(name)} #{inspect(attr)}"
          end
        end)
      end
    end)
  end

  defp merge(one, two) do
    Keyword.merge(one, two, &deep_resolve/3)
  end

  defp deep_resolve(_, one, two) when is_list(one) and is_list(two) do
    merge(one, two)
  end

  defp deep_resolve(_, _, two), do: two
end
