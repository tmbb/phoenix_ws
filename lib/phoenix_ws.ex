defmodule PhoenixWS do
  @moduledoc """
  Documentation for Phwocket.
  """

  defdelegate broadcast_with_endpoint(endpoint, topic, data), to: PhoenixWS.Channel

  defdelegate broadcast_with_endpoint!(endpoint, topic, data), to: PhoenixWS.Channel

  defdelegate broadcast_with_endpoint_from(endpoint, from, topic, data), to: PhoenixWS.Channel

  defdelegate broadcast_with_endpoint_from!(endpoint, from, topic, data), to: PhoenixWS.Channel

  defdelegate broadcast_from(ws, data), to: PhoenixWS.Channel

  defdelegate broadcast_from!(ws, data), to: PhoenixWS.Channel

  defdelegate broadcast(ws, data), to: PhoenixWS.Channel

  defdelegate broadcast!(ws, data), to: PhoenixWS.Channel
end
