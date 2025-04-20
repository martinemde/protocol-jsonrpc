# Protocol::Jsonrpc

A Ruby library for implementing JSON-RPC 2.0 protocol clients and servers.

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

- A `Protocol::Jsonrpc::Message` is the base class which represents JSON-RPC message structures
- A `Protocol::Jsonrpc::Framer` wraps an underlying stream (like a socket) for reading and writing JSON-RPC messages
- A `Protocol::Jsonrpc::Connection` wraps a framer and provides higher-level methods for communication
- Various message types including `RequestMessage`, `ResponseMessage`, `NotificationMessage`, and `ErrorMessage`

## Basic Usage

### Simple Example

Here's a basic example showing how to create a JSON-RPC connection over a socket pair:

```ruby
require 'protocol/jsonrpc'
require 'protocol/jsonrpc/connection'
require 'socket'

# Create a socket pair for testing
client_socket, server_socket = UNIXSocket.pair

# Create connections for both client and server
client = Protocol::Jsonrpc::Connection.new(Protocol::Jsonrpc::Framer.new(client_socket))
server = Protocol::Jsonrpc::Connection.new(Protocol::Jsonrpc::Framer.new(server_socket))

# Client sends a request
subtract = Protocol::Jsonrpc::RequestMessage.new(method: "subtract", params: [42, 23])
client.write(subtract)

# Server reads the request
message = server.read
# => <#Protocol::Jsonrpc::RequestMessage id:"...", method: "subtract", params: [42, 23]>

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

### Realistic Server Implementation

For a more realistic server implementation:

```ruby
require 'protocol/jsonrpc'
require 'protocol/jsonrpc/connection'
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

# Track pending requests awaiting responses
pending_requests = {}

# Main server loop
begin
  while (message = connection.read)
    case message
    when Protocol::Jsonrpc::RequestMessage
      puts "Received request: #{message.method}"

      if handlers.key?(message.method)
        result = handlers[message.method].call(message.params)
        connection.write(message.reply(result))
      else
        error = Protocol::Jsonrpc::MethodNotFoundError.new
        connection.write(message.reply(error))
      end

    when Protocol::Jsonrpc::NotificationMessage
      puts "Notification: #{message.method}"
      # Handle notification (no response needed)

    when Protocol::Jsonrpc::ResponseMessage
      puts "Response: #{message.result}"
      # Process response for an earlier request
      request = pending_requests.delete(message.id)
      request.call(message) if request

    when Protocol::Jsonrpc::ErrorMessage
      puts "Error: #{message.error.message}"
      request = pending_requests.delete(message.id)
      request.call(message) if request
    end
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
request = Protocol::Jsonrpc::RequestMessage.new(
  method: "subtract",
  params: [42, 23],
  id: 1  # Optional, auto-generated if not provided
)

# Create a request with named parameters
request = Protocol::Jsonrpc::RequestMessage.new(
  method: "subtract",
  params: { minuend: 42, subtrahend: 23 },
  id: 2
)
```

### Notification Message

Notifications are similar to requests but don't expect a response:

```ruby
notification = Protocol::Jsonrpc::NotificationMessage.new(
  method: "update",
  params: [1, 2, 3, 4, 5]
)
```

### Response Message

Typically created by replying to a request:

```ruby
# From a request object
response = request.reply(19)

# Or directly
response = Protocol::Jsonrpc::ResponseMessage.new(
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

# Standard error types include:
# - ParseError
# - InvalidRequestError
# - MethodNotFoundError
# - InvalidParamsError
# - InternalError
# - ServerError
```

## Batch Processing

JSON-RPC supports batch requests and responses:

```ruby
batch = [
  Protocol::Jsonrpc::RequestMessage.new(method: "sum", params: [1, 2, 4]),
  Protocol::Jsonrpc::NotificationMessage.new(method: "notify_hello", params: [7]),
  Protocol::Jsonrpc::RequestMessage.new(method: "subtract", params: [42, 23])
]

# Send batch request
client.write(batch)

# Process batch on server
messages = server.read

batch_response = messages.filter_map do |msg|
  case msg
  when Protocol::Jsonrpc::RequestMessage
    # Only add responses for requests, not notifications
    if msg.method == "sum"
      msg.reply(msg.params.sum)
    elsif msg.method == "subtract"
      msg.reply(msg.params.reduce(:-))
    else
      msg.reply(Protocol::Jsonrpc::MethodNotFoundError.new)
    end
  when Protocol::Jsonrpc::NotificationMessage
    handle_notification(msg)
    nil
  end
end

# Send batch response if not empty
server.write(batch_response) unless batch_response.empty?
```

## Custom Framers

The supplied Framer is designed for a bidirectional socket.
You can also supply your own framer:

```ruby
class MyFramer
  def flush; end
  def close; end

  # Return an object that response to unpack
  def read_frame
  end

  # Accepts a
  def write_frame(frame)
  end
end


client = Protocol::Jsonrpc::Connection.new(MyFramer.new)
client.read # calls read_frame, calling unpack on the returned object

message = Protocol::Jsonrpc::NotificationMessage.new(method: "hello", params: ["world"])
client.write(message) # calls write_frame with any message responding to `as_json`

```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/martinemde/protocol-jsonrpc.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
