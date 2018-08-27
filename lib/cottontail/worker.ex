defmodule Cottontail.Worker do
  @moduledoc false
  use GenServer

  def start_link(spec) do
    GenServer.start_link(__MODULE__, spec)
  end

  def init(spec) do
    {:ok, spec}
  end

  def handle_deliver(pid, msg, meta) do
    GenServer.call(pid, {:deliver, msg, meta})
  end

  def handle_call({:deliver, msg, meta}, _, spec) do
    result = spec.(msg, meta)

    {:reply, result, spec}
  end
end
