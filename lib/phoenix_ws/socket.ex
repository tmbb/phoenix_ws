defmodule PhoenixWS.Socket do
  require Phoenix.Socket

  defmacro channel(topic_pattern, module, opts \\ []) do
    quote do
      Phoenix.Socket.channel(
        unquote(topic_pattern),
        unquote(module),
        unquote(opts)
      )
    end
  end
end
