defmodule Cottontail.BrokerTest do
  @moduledoc false
  use ExUnit.Case

  alias Cottontail.Broker

  setup do
    {:ok, pid} = Broker.start_link(%Broker{
      queue_pid: self(),
      dispatcher_pid: self()
    })

    {:ok, pid: pid}
  end

  describe "Cottontail.Broker" do
    test "can forward a consume message to a dispatcher", %{pid: pid} do
      send pid, {:basic_deliver, "hello", %{delivery_tag: "123"}}

      assert_receive {:dispatch, "hello", %{delivery_tag: "123"}}
    end

    test "can send an ack when a worker succeeds", %{pid: pid} do
      send pid, {:consume_ok, "123"}

      assert_receive {:ack, "123"}
    end

    test "can send a reject when a worker fails", %{pid: pid} do
      send pid, {:consume_error, "oh noes", "123"}

      assert_receive {:reject, "oh noes", "123"}
    end
  end
end
