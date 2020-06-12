defmodule PhoenixWS.Channel do
  @server_sent_event "s"
  @client_sent_event "c"
  @data_key "d"

  def broadcast_with_endpoint(endpoint, topic, data) do
    endpoint.broadcast(topic, data)
  end

  def broadcast_with_endpoint!(endpoint, topic, data) do
    endpoint.broadcast!(topic, data)
  end

  def broadcast_with_endpoint_from(endpoint, from, topic, data) do
    endpoint.broadcast(from, topic, @server_sent_event, data)
  end

  def broadcast_with_endpoint_from!(endpoint, from, topic, data) do
    endpoint.broadcast!(from, topic, @server_sent_event, data)
  end

  def broadcast_from(ws, data) do
    Phoenix.Channel.broadcast_from(ws, @server_sent_event, %{@data_key => data})
  end

  def broadcast_from!(ws, data) do
    Phoenix.Channel.broadcast_from!(ws, @server_sent_event, %{@data_key => data})
  end

  def broadcast(ws, data) do
    Phoenix.Channel.broadcast(ws, @server_sent_event, %{@data_key => data})
  end

  def broadcast!(ws, data) do
    Phoenix.Channel.broadcast!(ws, @server_sent_event, %{@data_key => data})
  end

  defmacro __using__(opts) do
    web_module = Keyword.fetch!(opts, :web)

    quote do
      use unquote(web_module), :channel
      # Hide a bunch of imports from Phoenix channel...
      import Phoenix.Channel,
        except: [
          broadcast_from: 4,
          broadcast_from!: 4,
          broadcast!: 3,
          broadcast: 3
        ]

      # ... and replace them by the PhoenixWS versions
      import PhoenixWS.Channel

      def handle_in(unquote(@client_sent_event), %{unquote(@data_key) => data}, socket) do
        phoenix_ws_in(data, socket)
      end

      # An equivalent to the handle_out callback is not yet supported.
      # Maybe it should never be...
    end
  end
end
