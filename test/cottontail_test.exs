defmodule CottontailTest do
  use ExUnit.Case

  alias Cottontail.Example

  setup do
    {:ok, _} = Example.start_link([])

    :ok
  end

  describe "Cottontail" do
    test "can be used to declare a queue module" do
      Example.publish("hello this is a message")
    end
  end
end
