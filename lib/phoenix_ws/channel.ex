defmodule PhoenixWS.Channel do
  # Hardcoded names for client and server-sent events
  @server_sent_event "s"
  @client_sent_event "c"
  # Hardcoded key for the message in the JSON map
  @data_key "d"

  @doc """
  Handle an incomming websocket message.

  It takes the following arguments:
    * `data`: the binary message
      (websockets can send raw binary data and not only JSON, unlike Phoenix channels)
    * `socket`: a `Phoenix.Socket` struct.
  """
  @callback phoenix_ws_in(data :: String.t(), socket :: Phoenix.Socket.t()) ::
    {:noreply, Phoenix.Socket.t()}
    | {:noreply, Phoenix.Socket.t(), timeout() | :hibernate}
    | {:reply, Phoenix.Channel.reply(), Phoenix.Socket.t()}
    | {:stop, reason :: term(), Phoenix.Socket.t()}
    | {:stop, reason :: term(), Phoenix.Channel.reply(), Phoenix.Socket.t()}

  @doc """
  TODO
  """
  def broadcast_with_endpoint(endpoint, topic, data) do
    endpoint.broadcast(topic, @server_sent_event, %{@data_key => data})
  end

  @doc """
  TODO
  """
  def broadcast_with_endpoint!(endpoint, topic, data) do
    endpoint.broadcast!(topic, @server_sent_event, %{@data_key => data})
  end

  @doc """
  TODO
  """
  def broadcast_with_endpoint_from(endpoint, from, topic, data) do
    endpoint.broadcast(from, topic, @server_sent_event, %{@data_key => data})
  end

  @doc """
  TODO
  """
  def broadcast_with_endpoint_from!(endpoint, from, topic, data) do
    endpoint.broadcast!(from, topic, @server_sent_event, %{@data_key => data})
  end

  @doc """
  Same as `Phoenix.Channel.broadcast_from/3`, but through a Phoenix Websocket channel.
  It doesn't take an event name as the first argument.
  Websockets don't support different kinds of events!.
  """
  def broadcast_from(ws, data) do
    Phoenix.Channel.broadcast_from(ws, @server_sent_event, %{@data_key => data})
  end

  @doc """
  Same as `Phoenix.Channel.broadcast_from!/3`, but through a Phoenix Websocket channel.
  It doesn't take an event name as the first argument.
  Websockets don't support different kinds of events!.
  """
  def broadcast_from!(ws, data) do
    Phoenix.Channel.broadcast_from!(ws, @server_sent_event, %{@data_key => data})
  end

  @doc """
  Same as `Phoenix.Channel.broadcast/3`, but through a Phoenix Websocket channel.
  It doesn't take an event name as the first argument.
  Websockets don't support different kinds of events!.
  """
  def broadcast(ws, data) do
    Phoenix.Channel.broadcast(ws, @server_sent_event, %{@data_key => data})
  end

  @doc """
  Same as `Phoenix.Channel.broadcast!/3`, but through a Phoenix Websocket channel.
  It doesn't take an event name as the first argument.
  Websockets don't support different kinds of events!.
  """
  def broadcast!(ws, data) do
    Phoenix.Channel.broadcast!(ws, @server_sent_event, %{@data_key => data})
  end

  defmacro __using__(_opts) do
    quote do
      use Phoenix.Channel

      # Hide a bunch of imports from Phoenix channel so that the user doesn't use them accidentally.
      # If the user wants to use them (they probably really don't), they can always re-import them
      # or call them by their fully qualified name.
      import Phoenix.Channel,
        except: [
          broadcast_from: 4,
          broadcast_from!: 4,
          broadcast!: 3,
          broadcast: 3,
          push: 3
        ]

      # If users wants to broadcast to a Phoenix Websocket, they should use `PhoenixWS.broadcast/2` and so on.

      @impl Phoenix.Channel
      def handle_in(unquote(@client_sent_event), %{unquote(@data_key) => data}, socket) do
        # Will raise na error if the used doesn't provide a `phoenix_ws_in` callback
        case phoenix_ws_in(data, socket) do
          # If we're going to reply to the client, we must translate the `phoenix_ws` message
          # into a Phoenix Channel message.
          {:reply, reply, new_socket} ->
            new_reply = %{unquote(@data_key) => reply}
            {:reply, new_reply, new_socket}

          {:stop, reason, reply, new_socket} ->
            new_reply = %{unquote(@data_key) => reply}
            {:stop, reason, new_reply, new_socket}

          # Other return types in which there is no reply
          other ->
            other
        end
      end

      # An equivalent to the handle_out callback is not yet supported.
      # Maybe it should never be...
    end
  end
end
