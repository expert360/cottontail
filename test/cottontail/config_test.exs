defmodule Cottontail.ConfigTest do
  @moduledoc false

  use ExUnit.Case

  alias Cottontail.Config

  setup do
    Application.put_env(:cottontail, :defaults, [
      queue: [
        url: "amqp://keanu:password@localhost:5672",
        exchange: {"cfg.test", :direct}
      ],
      dispatcher: [
        pool_size: 13,
        pool_overflow: 99
      ]
    ])

    :ok
  end

  describe "Cottontail.Config" do
    test "can merge default config with provided" do
      worker = fn _, _ -> :ok end

      cfg = [
        queue: [
          routing_key: "foo"
        ],
        dispatcher: [
          worker: worker
        ]
      ]

      {:ok, merged} = Config.process_config(cfg)

      assert merged == [
        queue: [
          url: "amqp://keanu:password@localhost:5672",
          exchange: {"cfg.test", :direct},
          routing_key: "foo"
        ],
        dispatcher: [
          pool_size: 13,
          pool_overflow: 99,
          worker: worker
        ]
      ]
    end

    test "allows config in place to override defaults" do
      worker = fn _, _ -> :ok end

      cfg = [
        queue: [
          url: "amqp://user:pass@example.com:1234",
          routing_key: "baz",
          exchange: {"cfg.test", :topic}
        ],
        dispatcher: [
          pool_size: 2,
          pool_overflow: 3,
          worker: worker
        ]
      ]

      {:ok, merged} = Config.process_config(cfg)

      assert merged == cfg
    end

    test "can verify a valid config" do
      cfg = [
        queue: [
          routing_key: "bar"
        ],
        dispatcher: [
          worker: fn _, _ -> :ok end
        ]
      ]

      {:ok, merged} = Config.process_config(cfg)

      assert Config.validate_config!(merged) == merged
    end

    test "can reject a config with missing groups" do
      cfg = []

      assert_raise ArgumentError, "Config is missing for: :queue", fn ->
        Config.validate_config!(cfg)
      end
    end

    test "can reject a config with missing params" do
      cfg = [
        dispatcher: [
          worker: fn _, _ -> :ok end
        ]
      ]

      {:ok, merged} = Config.process_config(cfg)

      assert_raise ArgumentError, "Config is missing for: :queue :routing_key",
                   fn ->
                     Config.validate_config!(merged)
                   end
    end
  end
end
