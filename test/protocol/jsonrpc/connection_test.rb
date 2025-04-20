# frozen_string_literal: true

require_relative "../../test_helper"
require "socket"
require "protocol/jsonrpc/connection"
require "protocol/jsonrpc/message"
require "protocol/jsonrpc/framer"
require "protocol/jsonrpc/error"
require "protocol/jsonrpc/error_message"
require "protocol/jsonrpc/request_message"
require "protocol/jsonrpc/response_message"
require "protocol/jsonrpc/notification_message"

module Protocol
  module Jsonrpc
    class ConnectionTest < Minitest::Test
      def setup
        @client_socket, @server_socket = UNIXSocket.pair
        @client = Connection.new(Framer.new(@client_socket))
        @server = Connection.new(Framer.new(@server_socket))
      end

      def teardown
        @client_socket.close
        @server_socket.close
      end

      # Tests the JSON-RPC example:
      # --> {"jsonrpc": "2.0", "method": "subtract", "params": [42, 23], "id": 1}
      # <-- {"jsonrpc": "2.0", "result": 19, "id": 1}
      def test_request_with_positional_parameters
        subtract = RequestMessage.new(method: "subtract", params: [42, 23])
        @client.write(subtract)

        message = @server.read
        assert_equal subtract, message
        @server.write(message.reply(19))

        response = @client.read
        assert_equal 19, response.result
      end

      # Tests the JSON-RPC example:
      # --> {"jsonrpc": "2.0", "method": "subtract", "params": {"subtrahend": 23, "minuend": 42}, "id": 3}
      # <-- {"jsonrpc": "2.0", "result": 19, "id": 3}
      def test_request_with_named_parameters
        subtract = RequestMessage.new(method: "subtract", params: { subtrahend: 23, minuend: 42 })
        @client.write(subtract)

        message = @server.read
        assert_equal subtract, message
        @server.write(message.reply(19))

        response = @client.read
        assert_equal 19, response.result
      end

      # Tests the JSON-RPC example:
      # --> {"jsonrpc": "2.0", "method": "update", "params": [1,2,3,4,5]}
      # --> {"jsonrpc": "2.0", "method": "foobar"}
      def test_notification
        update = NotificationMessage.new(method: "update", params: [1, 2, 3, 4, 5])
        @client.write(update)

        message = @server.read
        assert_equal update, message

        foobar = NotificationMessage.new(method: "foobar")
        @client.write(foobar)

        message = @server.read
        assert_equal foobar, message
      end

      # Tests the JSON-RPC example:
      # --> {"jsonrpc": "2.0", "method": "foobar", "id": "1"}
      # <-- {"jsonrpc": "2.0", "error": {"code": -32601, "message": "Method not found"}, "id": "1"}
      def test_method_not_found_error
        foobar = RequestMessage.new(method: "foobar")
        @client.write(foobar)

        message = @server.read
        assert_equal foobar, message

        @server.write(message.reply(MethodNotFoundError.new))

        response = @client.read
        assert_instance_of ErrorMessage, response
        assert_equal Error::METHOD_NOT_FOUND, response.error.code
        assert_equal "Method not found", response.error.message
      end

      # Tests the JSON-RPC example:
      # --> {"jsonrpc": "2.0", "method": "foobar, "params": "bar", "baz]
      # <-- {"jsonrpc": "2.0", "error": {"code": -32700, "message": "Parse error"}, "id": null}
      def test_parse_error
        # For parse errors, we can't use the Connection object directly since it would catch the parse error
        # Instead, we'll write invalid JSON directly to the socket
        @client_socket.write(<<~MESSAGE)
          {"jsonrpc": "2.0", "method": "foobar, "params": "bar", "baz]
        MESSAGE
        @client_socket.flush

        error = assert_raises(ParseError) { @server.read }
        assert_equal Error::PARSE_ERROR, error.code
        assert_match(/Parse error/, error.message)
      end

      # Tests the JSON-RPC example:
      # --> {"jsonrpc": "2.0", "method": 1, "params": "bar"}
      # <-- {"jsonrpc": "2.0", "error": {"code": -32600, "message": "Invalid Request"}, "id": null}
      def test_invalid_request_error
        # For invalid request errors, we need to send a valid JSON but invalid request
        @client_socket.write(<<~MESSAGE)
          {"jsonrpc": "2.0", "method": 1, "params": "bar"}
        MESSAGE
        @client_socket.flush

        error = assert_raises(InvalidRequestError) { @server.read }
        assert_equal Error::INVALID_REQUEST, error.code
        assert_equal "Invalid Request: Method must be a string", error.message
      end

      # Tests the JSON-RPC example:
      # --> [
      #   {"jsonrpc": "2.0", "method": "sum", "params": [1,2,4], "id": "1"},
      #   {"jsonrpc": "2.0", "method"
      # ]
      # <-- {"jsonrpc": "2.0", "error": {"code": -32700, "message": "Parse error"}, "id": null}
      def test_batch_request_with_invalid_json
        @client_socket.write(<<~MESSAGE)
          [{"jsonrpc": "2.0", "method": "sum", "params": [1,2,4], "id": "1"},{"jsonrpc": "2.0", "method"]
        MESSAGE
        @client_socket.flush

        assert_raises(ParseError) { @server.read }

        response = ParseError.new("Parse error").reply
        @server.write(response)

        response = @client.read
        assert_instance_of ErrorMessage, response
        assert_equal Error::PARSE_ERROR, response.error.code
        assert_match(/Parse error/, response.error.message)
        assert_nil response.id
      end

      # Tests the JSON-RPC example:
      # --> []
      # <-- {"jsonrpc": "2.0", "error": {"code": -32600, "message": "Invalid Request"}, "id": null}
      def test_empty_batch_request
        @client_socket.write(<<~MESSAGE)
          []
        MESSAGE
        @client_socket.flush

        assert_raises(InvalidRequestError) { @server.read }

        response = InvalidRequestError.new("Invalid Request").reply
        @server.write(response)

        response = @client.read
        assert_instance_of ErrorMessage, response
        assert_equal Error::INVALID_REQUEST, response.error.code
        assert_match(/Invalid Request/, response.error.message)
        assert_nil response.id
      end

      # Tests the JSON-RPC example:
      # --> [1]
      # <-- [
      #   {"jsonrpc": "2.0", "error": {"code": -32600, "message": "Invalid Request"}, "id": null}
      # ]
      def test_invalid_batch_request
        @client_socket.write(<<~MESSAGE)
          [1]
        MESSAGE
        @client_socket.flush

        messages = @server.read
        assert_instance_of InvalidRequestError, messages[0]

        response = messages.map do |message|
          message.reply
        end

        @server.write(response)

        response = @client.read
        assert_instance_of Array, response
        assert_equal 1, response.length
        error_response = response.first

        assert_instance_of ErrorMessage, error_response
        assert_equal Error::INVALID_REQUEST, error_response.error.code
        assert_match(/Invalid Request/, error_response.error.message)
        assert_nil error_response.id
      end

      # Tests the JSON-RPC example:
      # --> [1,2,3]
      # <-- [
      #   {"jsonrpc": "2.0", "error": {"code": -32600, "message": "Invalid Request"}, "id": null},
      #   {"jsonrpc": "2.0", "error": {"code": -32600, "message": "Invalid Request"}, "id": null},
      #   {"jsonrpc": "2.0", "error": {"code": -32600, "message": "Invalid Request"}, "id": null}
      # ]
      def test_multiple_invalid_batch_request
        @client_socket.write(<<~MESSAGE)
          [1,2,3]
        MESSAGE
        @client_socket.flush

        messages = @server.read
        assert_equal 3, messages.length
        assert_instance_of InvalidRequestError, messages[0]
        assert_instance_of InvalidRequestError, messages[1]
        assert_instance_of InvalidRequestError, messages[2]

        response = messages.map do |message|
          message.reply
        end
        @server.write(response)

        response = @client.read
        assert_instance_of Array, response
        assert_equal 3, response.length

        response.each do |error_response|
          assert_instance_of ErrorMessage, error_response
          assert_equal Error::INVALID_REQUEST, error_response.error.code
          assert_match(/Invalid Request/, error_response.error.message)
          assert_nil error_response.id
        end
      end

      # Tests the JSON-RPC example:
      # --> [
      #       {"jsonrpc": "2.0", "method": "sum", "params": [1,2,4], "id": "1"},
      #       {"jsonrpc": "2.0", "method": "notify_hello", "params": [7]},
      #       {"jsonrpc": "2.0", "method": "subtract", "params": [42,23], "id": "2"},
      #       {"foo": "boo"},
      #       {"jsonrpc": "2.0", "method": "foo.get", "params": {"name": "myself"}, "id": "5"},
      #       {"jsonrpc": "2.0", "method": "get_data", "id": "9"}
      #   ]
      # <-- [
      #       {"jsonrpc": "2.0", "result": 7, "id": "1"},
      #       {"jsonrpc": "2.0", "result": 19, "id": "2"},
      #       {"jsonrpc": "2.0", "error": {"code": -32600, "message": "Invalid Request"}, "id": null},
      #       {"jsonrpc": "2.0", "error": {"code": -32601, "message": "Method not found"}, "id": "5"},
      #       {"jsonrpc": "2.0", "result": ["hello", 5], "id": "9"}
      #   ]
      def test_batch_request
        batch = [
          RequestMessage.new(method: "sum", params: [1, 2, 4], id: "1"),
          NotificationMessage.new(method: "notify_hello", params: [7]),
          RequestMessage.new(method: "subtract", params: [42, 23], id: "2"),
          { foo: "boo" }, # Invalid request
          RequestMessage.new(method: "foo.get", params: { name: "myself" }, id: "5"),
          RequestMessage.new(method: "get_data", id: "9")
        ]

        @client.write(batch)

        message = @server.read
        assert_instance_of Array, message
        assert_equal 6, message.length

        # Create batch response
        batch_response = [
          message[0].reply(7),
          message[2].reply(19),
          InvalidRequestError.new("Invalid Request").reply,
          message[4].reply(MethodNotFoundError.new("Method not found")),
          message[5].reply(["hello", 5])
        ]

        @server.write(batch_response)

        response = @client.read
        assert_instance_of Array, response
        assert_equal 5, response.length

        assert_equal 7, response[0].result
        assert_equal 19, response[1].result
        assert_equal Error::INVALID_REQUEST, response[2].error.code
        assert_equal Error::METHOD_NOT_FOUND, response[3].error.code
        assert_equal ["hello", 5], response[4].result
      end

      # Tests the JSON-RPC example:
      # --> [
      #       {"jsonrpc": "2.0", "method": "notify_sum", "params": [1,2,4]},
      #       {"jsonrpc": "2.0", "method": "notify_hello", "params": [7]}
      #   ]
      # <-- //Nothing is returned for all notification batches
      def test_batch_notification
        batch = [
          NotificationMessage.new(method: "notify_sum", params: [1, 2, 4]),
          NotificationMessage.new(method: "notify_hello", params: [7])
        ]

        @client.write(batch)

        message = @server.read
        assert_instance_of Array, message
        assert_equal 2, message.length
        assert message.all? { |req| req.is_a?(NotificationMessage) }

        # No response is expected for notification batches
        # But we can verify the messages were received correctly
        assert_equal "notify_sum", message[0].method
        assert_equal [1, 2, 4], message[0].params
        assert_equal "notify_hello", message[1].method
        assert_equal [7], message[1].params
      end
    end
  end
end
