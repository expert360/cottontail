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

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)

      @before_compile unquote(__MODULE__)
    end
  end

  defmacro connection(desc, do: block) do
    quote do
      @cottontail_spec %Cottontail{
        description: unquote(desc)
      }

      unquote(block)
    end
  end

  defmacro queue(opts) do
    __set_to_spec__(Queue, :queue, opts)
  end

  defmacro dispatcher(opts) do
    __set_to_spec__(Dispatcher, :dispatcher, opts)
  end

  defmacro __before_compile__(_) do
    quote do
      use GenServer

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

  defp __set_to_spec__(type, key, opts) do
    quote do
      __MODULE__
      |> Module.get_attribute(:cottontail_spec)
      |> Map.put(unquote(key), struct(unquote(type), unquote(opts)))
      |> (&(Module.put_attribute(__MODULE__, :cottontail_spec, &1))).()
    end
  end
end
