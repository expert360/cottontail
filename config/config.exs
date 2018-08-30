
use Mix.Config

url = System.get_env("AMQP_URL")

config :cottontail, amqp_url: url
config :cottontail, defaults: [
  queue: [
    url: url,
    exchange: {"test.main", :direct}
  ],
  dispatcher: [
    pool_size: 5,
    pool_overflow: 5
  ]
]
