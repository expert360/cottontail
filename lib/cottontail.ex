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
    Config,
    Dispatcher,
    Queue
  }

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
    {:ok, cfg} = Config.process_config([
      description: Module.get_attribute(mod, :description),
      queue: Module.get_attribute(mod, :queue),
      dispatcher: Module.get_attribute(mod, :dispatcher)
    ])

    Config.validate_config!(cfg)

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
        Broker.start_link(%{
          queue: @cottontail_spec.queue,
          dispatcher: @cottontail_spec.dispatcher
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
end
