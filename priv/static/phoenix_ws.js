class PhoenixWS {
  // Build a new PhoenixWS, or "Phoenix Web Socket"
  // Currently we are not very good at handling reconnects and such.
  // There are probably places where we are not very compatible...
  constructor(socket, topic, initialPayload) {
    // The "blob" type is probably a better choice for most applications
    this.binaryType = "blob";
    // Find a better way of dealing with "bufferedAmount"
    this.bufferedAmount = 0;
    // It should be initialized as null according to the spec;
    // I don't think I'll ever want to support any Websocket extensions here
    this.extensions = "";

    // This is for the user to override
    this.onerror = (error) => {
      console.error('failed to connect', error);
    };

    // This is for the user to override
    this.onmessage = (_) => { return null; };

    // This is for the user to override
    this.onclose = () => {
      return null;
    };

    // This is for the user to override
    this.onopen = () => {
      return null;
    };

    this.protocol = null;
    this.readyState = WebSocket.CONNECTING;
    this.url = null;

    // Setup the Phoenix Web Socket:

    // First, we attach the PhoenixWS to a Phoenix Socket
    this.socket = socket;
    // Then, we create a channel belonging to that socket.
    // Messages sent to the PhoenixWS will be actually sent to the channel
    // after some processing.
    let channel = socket.channel(topic, initialPayload);

    // Join the channel (this is equivalent to connecting a websocket)
    channel
      .join()
      // If we were able to join a channel, the PhoenixWS is open and can receive messages
      // the `readyState` is set to `OPEN`.
      .receive("ok", response => {
        console.log("Joined successfully", response)
        this.readyState = WebSocket.OPEN;
      })
      // If we weren't able to join, just call the error handler.
      .receive("error", response => {
        this.readyState = WebSocket.CLOSED;
        this.onerror(response)
      })

    // Now let's handle messages from the server.
    // Phoenix channels expect messages to be part of an "event".
    // The event name is a string.
    // For PhoenixWSs we'll arbitrarily use the "s" event (S from Server).
    channel
      .on("s", (channelMessage) => {
        console.log(channelMessage);
        // The `WebSocket.onmessage(event)` expects a `MessageEvent` and not a raw map
        // like the one Phoenix sends to the channel.
        // Because we need to be compatible with the `WebSocket.onmessage(event)` method,
        // we'll build a `MessageEvent` on the spot.
        let websocketMessageEvent = this._makeMessageEvent(channelMessage);
        // We then call the handler on the `MessageEvent` so that we act
        // as a well-behaved WebSocket
        this.onmessage(websocketMessageEvent);
      })

    // Attach the channel to the PhoenixWS
    this.channel = channel;
  }

  // Public Methods

  close(code, reason) {
    // TODO: Replace this with a real implementation
    console.log("Closed!");
  }

  // We have already a way to handle data that comes from the server.
  // We've had to translate Channel messages into what a websocket expects.
  // Now we'll do the opposite and translate a websocket message (which is just raw binary data)
  // into the kind of message a Phoenix channel expects.
  // This adds some extra bytes to the message, but Phoenix is really inflexible regarding
  // what it accepts as a message, so it's a price we must be ready to pay.
  send(data) {
    // Phoenix expects a message to be a map instead of arbitrary data.
    // We need to wrap the raw data into a map.
    // We arbitrarily use the `d` key (D from Data).
    // We use a one-letter key to save bytes over the network.
    let channelMessage = { d: data };
    this.channel.push("c", channelMessage, 10000)
      .receive("ok", (msg) => console.log("created message", msg))
      .receive("error", (reasons) => {
        this.readyState = WebSocket.CLOSED;
        this.onerror(reasons)
      })
      .receive("timeout", () => {
        this.readyState = WebSocket.CLOSED;
        // TODO: What is the right way to call the error handler?
        this.onerror(null);
      })
  }

  // Private Methods

  _makeMessageEvent(channelMessage) {
    // Extract the data from the channel message
    // (sadly, channel messages must be maps and can't be raw strings...)
    //
    // The raw `data` in a channel message is the value of the "d" key:
    let data = channelMessage.d;
    // Build an event like the one a websocket would return
    let event = new MessageEvent("websocket", {
      data: data,
      // The other items in the map will be filled with the default values.
      // They save no purpose other than documentation
      origin: "",
      lastEventId: "",
      source: null,
      ports: []
    })

    return event;
  }
}

export default PhoenixWS