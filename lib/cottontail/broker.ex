defmodule Cottontail.Broker do
  @moduledoc false

  @type t :: %__MODULE__{}

  defstruct [
    :queue_pid,
    :dispatcher_pid
  ]

  def start_link(spec) do
    GenServer.start_link(__MODULE__, spec)
  end

  def init(spec) do
    {:ok, spec}
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
