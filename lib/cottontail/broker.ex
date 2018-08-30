defmodule Cottontail.Broker do
  @moduledoc false

  alias Cottontail.{Dispatcher, Queue}

  def start_link(spec) do
    GenServer.start_link(__MODULE__, spec)
  end

  def init(%{queue: q, dispatcher: d}) do
    {:ok, q_pid} = Queue.start_link(Map.put(q, :broker_pid, self()))
    {:ok, d_pid} = Dispatcher.start_link(Map.put(d, :broker_pid, self()))

    {:ok, %{
      queue_pid: q_pid,
      dispatcher_pid: d_pid
    }}
  end
  def init(%{queue_pid: q_pid, dispatcher_pid: d_pid}) do
    {:ok, %{
      queue_pid: q_pid,
      dispatcher_pid: d_pid
    }}
  end

  def handle_info({:basic_deliver, msg, meta}, spec) do
    send spec.dispatcher_pid, {:dispatch, msg, meta}

    {:noreply, spec}
  end
  def handle_info({:consume_ok, tag}, spec) do
    send spec.queue_pid, {:ack, tag}

    {:noreply, spec}
  end
  def handle_info({:consume_error, msg, tag}, spec) do
    send spec.queue_pid, {:reject, msg, tag}

    {:noreply, spec}
  end
  def handle_info({:publish, msg}, spec) do
    send spec.queue_pid, {:publish, msg}

    {:noreply, spec}
  end
end
