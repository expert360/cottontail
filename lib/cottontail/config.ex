defmodule Cottontail.Config do
  @moduledoc "Configuration helper"

  @required [
    queue: [:url, :exchange, :routing_key],
    dispatcher: [:worker]
  ]

  def process_config(cfg) do
    defaults = Application.get_env(:cottontail, :defaults, [])

    {:ok, merge(defaults, cfg)}
  end

  def validate_config!(cfg) do
    Enum.each(@required, fn {name, attrs} ->
      sub = Keyword.get(cfg, name, nil)

      if is_nil(sub) do
        raise ArgumentError, "Config is missing for: #{inspect(name)}"
      else
        Enum.each(attrs, fn attr ->
          if is_nil(Keyword.get(sub, attr, nil)) do
            raise ArgumentError, "Config is missing for: #{inspect(name)} #{inspect(attr)}"
          end
        end)
      end
    end)

    cfg
  end

  defp merge(one, two) do
    Keyword.merge(one, two, &deep_resolve/3)
  end

  defp deep_resolve(_, one, two) when is_list(one) and is_list(two) do
    merge(one, two)
  end

  defp deep_resolve(_, _, two), do: two
end
