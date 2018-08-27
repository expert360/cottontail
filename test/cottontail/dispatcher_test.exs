defmodule Cottontail.DispatcherTest do
  @moduledoc false
  use ExUnit.Case

  alias Cottontail.Dispatcher

  describe "Cottontail.Dispatcher" do
    test "can dispatch a message and report success to the broker" do
      me = self()

      {:ok, pid} = Dispatcher.start_link(%{
        broker_pid: me,
        pool_size: 5,
        pool_overflow: 10,
        worker: fn _, _ ->
          :ok
        end
      })

      send pid, {:dispatch, "hello", %{delivery_tag: "123"}}

      assert_receive {:consume_ok, "123"}, 1_000
    end

    test "can dispatch a message and report failure to the broker" do
      me = self()

      {:ok, pid} = Dispatcher.start_link(%{
        broker_pid: me,
        pool_size: 5,
        pool_overflow: 10,
        worker: fn _, _ ->
          {:error, "it's all bad"}
        end
      })

      send pid, {:dispatch, "bad", %{delivery_tag: "321"}}

      assert_receive {:consume_error, "it's all bad", "321"}, 1_000
    end
  end
end
