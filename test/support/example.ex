defmodule Cottontail.Example do
  @moduledoc false

  use Cottontail

  connection "an example implementation for tests" do
    queue routing_key: "v1.test",
          consumer: true

    dispatcher worker: &__MODULE__.handle_deliver/2
  end

  def handle_deliver(_, _), do: :ok
end
