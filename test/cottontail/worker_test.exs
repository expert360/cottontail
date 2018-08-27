defmodule Cottontail.WorkerTest do
  @moduledoc false
  use ExUnit.Case

  alias Cottontail.Worker

  describe "Cottontail.Worker" do
    test "can take a message and handle it" do
      me = self()

      {:ok, pid} = Worker.start_link(fn msg, meta ->
        send me, {:msg, msg}
        send me, {:meta, meta}

        :ok
      end)

      assert Worker.handle_deliver(pid, "hello", "it'sa me") == :ok
      assert_receive {:msg, "hello"}
      assert_receive {:meta, "it'sa me"}
    end
  end
end
