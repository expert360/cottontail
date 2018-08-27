
use Mix.Config

config :cottontail, amqp_url: System.get_env("AMQP_URL")
