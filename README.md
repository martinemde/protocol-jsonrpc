# Protocol::Jsonrpc

A Ruby library for implementing JSON-RPC 2.0 protocol clients and servers.

Design influenced by [protocol-websocket](https://github.com/socketry/protocol-websocket) by Samuel Williams ([@ioquatix](https://github.com/ioquatix)).
Thanks Samuel!

## Installation

Add the gem to your project:

```bash
bundle add protocol-jsonrpc
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install protocol-jsonrpc
```

## Core Concepts

Protocol::Jsonrpc has several core concepts:

### `Protocol::Jsonrpc::Message`

This is the type which represents JSON-RPC message structures.

Each of the 4 JSONRPC message types has their own class which include the `Message` module.

- `Protocol::Jsonrpc::ErrorResponse`
- `Protocol::Jsonrpc::Notification`
- `Protocol::Jsonrpc::Request`
- `Protocol::Jsonrpc::Response`

### `Protocol::Jsonrpc::Framer`

This provides one implementation for an object that splits JSONRPC messages off of some sort of socket or communication layer.

The provided implementation wraps an underlying bi-directional stream (like a unixsocket) for reading and writing JSON-RPC messages.

### `Protocol::Jsonrpc::Connection`

This wraps a framer and provides higher-level methods for communication.


## Basic Usage

### Simple Example

Here's a basic example showing how to create a JSON-RPC connection over a socket pair:

```ruby
require 'protocol/jsonrpc'
require 'protocol/jsonrpc/connection'
require 'protocol/jsonrpc/framer'
require 'socket'

# Create a socket pair for testing
client_socket, server_socket = UNIXSocket.pair

# Create connections for both client and server
client = Protocol::Jsonrpc::Connection.new(Protocol::Jsonrpc::Framer.new(client_socket))
server = Protocol::Jsonrpc::Connection.new(Protocol::Jsonrpc::Framer.new(server_socket))

# Client sends a request
subtract = Protocol::Jsonrpc::Request.new(method: "subtract", params: [42, 23])
client.write(subtract)

# Server reads the request
message = server.read
# => <#Protocol::Jsonrpc::Request id:"...", method: "subtract", params: [42, 23]>

# Server processes the request (calculating the result)
result = message.params.inject(:-) if message.method == "subtract"

# Server sends a response
server.write(message.reply(result))

# Client reads the response
response = client.read
response.result # => 19

# Close connections
client.close
server.close
```

### Server Implementation

Here's a server implementation showing how to handle different message types:

```ruby
require 'protocol/jsonrpc'
require 'protocol/jsonrpc/connection'
require 'protocol/jsonrpc/framer'
require 'socket'

server = TCPServer.new('localhost', 4567)
socket = server.accept
connection = Protocol::Jsonrpc::Connection.new(Protocol::Jsonrpc::Framer.new(socket))

# Simple dispatcher for handling different methods
handlers = {
  "add" => ->(params) { params.sum },
  "subtract" => ->(params) { params.reduce(:-) },
  "multiply" => ->(params) { params.reduce(:*) },
  "divide" => ->(params) { params.reduce(:/) }
}

def handle_request(method, params)
  puts "Received request: #{method}"
  if handlers.key?(method)
    handlers[method].call(params)
  else
    raise Protocol::Jsonrpc::MethodNotFoundError.new
  end
end

# Main server loop
begin
  while (message = connection.read)
    response = message.reply do |message|
      if message.request?
        handle_request(message.method, message.params)
      elsif message.notification?
        puts "Notification: #{message.method}"
        # Handle notification (no response needed)
      end
    end
    connection.write(response)
  end
rescue Errno::EPIPE, IOError => e
  puts "Connection closed: #{e.message}"
ensure
  connection.close
  socket.close
  server.close
end
```

## Message Types

### Request Message

```ruby
# Create a request with positional parameters
request = Protocol::Jsonrpc::Request.new(
  method: "subtract",
  params: [42, 23],
  id: 1  # Optional, auto-generated if not provided
)

# Create a request with named parameters
request = Protocol::Jsonrpc::Request.new(
  method: "subtract",
  params: { minuend: 42, subtrahend: 23 },
  id: 2
)
```

### Notification Message

Notifications are similar to requests but don't expect a response:

```ruby
notification = Protocol::Jsonrpc::Notification.new(
  method: "update",
  params: { a: 1 }
)
```

### Response Message

Typically created by replying to a request:

```ruby
# From a request object
response = request.reply(19)

# Or directly
response = Protocol::Jsonrpc::Response.new(
  result: 19,
  id: 1
)
```

### Error Message

For error responses:

```ruby
# Create from an error object
error = Protocol::Jsonrpc::InvalidParamsError.new("Invalid parameters")
error_response = request.reply(error)
```

Error types represent the standard JSON-RPC error codes:

```ruby
Protocol::Jsonrpc::ParseError
Protocol::Jsonrpc::InvalidRequestError
Protocol::Jsonrpc::MethodNotFoundError
Protocol::Jsonrpc::InvalidParamsError
Protocol::Jsonrpc::InternalError
```

## Batch Processing

JSON-RPC supports batch requests and responses. The library returns a `Protocol::Jsonrpc::Batch` that acts like an array and provides a `reply` method for processing:

```ruby
# Send a batch request (client side)
batch = [
  Protocol::Jsonrpc::Request.new(method: "sum", params: [1, 2, 4]),
  Protocol::Jsonrpc::Notification.new(method: "notify_hello", params: [7]),
  Protocol::Jsonrpc::Request.new(method: "subtract", params: [42, 23])
]

client.write(batch)

# Process batch on server
batch = server.read

# Process each message in the batch using reply
batch_response = batch.reply do |message|
  case message
  when Protocol::Jsonrpc::Request
    # Handle request and return result
    if message.method == "sum"
      message.params.sum
    elsif message.method == "subtract"
      message.params.reduce(:-)
    else
      # raising during a reply block will automatically respond with an error
      raise Protocol::Jsonrpc::MethodNotFoundError.new
    end
  when Protocol::Jsonrpc::Notification
    # Handle notification (return value is ignored)
    handle_notification(message)
  end
end

# Send batch response (automatically includes responses for requests, not notifications)
server.write(batch_response)
```

Batch processing supports;

1. Consistent interface (`reply`) for both single and batch requests
2. Automatic error handling and response collection
3. Filters out nil responses (from notifications) automatically
4. Maintains protocol compliance by only responding to requests and handling malformed batches

## Custom Framers

The supplied Framer is designed for a bidirectional socket.
You can also supply your own framer by implementing the following interface:

```ruby
class MyFramer
  # Return a Frame object that contains the raw JSON
  def read_frame
    # Read JSON data from your source (e.g., HTTP body, WebSocket, etc.)
    raw_json = get_json_line_from_somewhere

    # Return a Frame object
    Protocol::Jsonrpc::Frame.new(raw_json: raw_json)
  end

  # Write a Frame object
  def write_frame(frame)
    # frame.raw_json contains the JSON string to send
    send_json_somewhere(frame.raw_json)
  end

  # Flush any buffered data
  def flush
    # Implementation depends on your transport
  end

  # Close the connection
  def close
    # Clean up resources
  end
end

client = Protocol::Jsonrpc::Connection.new(MyFramer.new)

# Read messages (calls framer.read_frame and unpacks the JSON)
message = client.read

# Write messages (packs to JSON and calls framer.write_frame)
client.write(Protocol::Jsonrpc::Notification.new(method: "hello", params: ["world"]))
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/martinemde/protocol-jsonrpc.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
