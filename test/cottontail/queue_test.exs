defmodule Cottontail.QueueTest do
  @moduledoc false
  use ExUnit.Case

  alias Cottontail.Queue

  defp amqp_url, do: Application.fetch_env!(:cottontail, :amqp_url)

  setup tags do
    type = tags[:exchange]

    me = self()

    {:ok, pid} = Queue.start_link(%{
      description: "a direct test queue for doing tests",
      broker_pid: me,
      url: amqp_url(),
      exchange: {"test.#{Atom.to_string(type)}", type},
      routing_key: "v1.queue",
      dlx_exchange: :auto,
      dlx_routing_key: :auto,
      durable: true,
      consumer: true
    })

    {:ok, pid: pid}
  end

  describe "Cottontail.Queue" do
    @tag exchange: :direct
    test "can publish and consume messages from a queue on a direct exchange", %{pid: pid} do
      Queue.publish(pid, "this is a message")

      assert_receive {:basic_deliver, "this is a message", _}
    end

    @tag exchange: :topic
    test "can publish and consume messages from a queue on a topic exchange", %{pid: pid} do
      Queue.publish(pid, "this is a message")

      assert_receive {:basic_deliver, "this is a message", _}
    end

    @tag exchange: :fanout
    test "can publish and consume messages from a queue on a fanout exchange", %{pid: pid} do
      Queue.publish(pid, "this is a message")

      assert_receive {:basic_deliver, "this is a message", _}
    end
  end
end
