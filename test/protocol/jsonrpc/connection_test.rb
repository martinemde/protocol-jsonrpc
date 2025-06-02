# frozen_string_literal: true

# Released under the MIT License.
# Copyright 2025 by Martin Emde

require "test_helper"

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
        subtract = Request.new(method: "subtract", params: [42, 23])
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
        subtract = Request.new(method: "subtract", params: {subtrahend: 23, minuend: 42})
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
        update = Notification.new(method: "update", params: [1, 2, 3, 4, 5])
        foobar = Notification.new(method: "foobar")
        @client.write(update)
        @client.write(foobar)

        message = @server.read
        assert_equal update, message

        message = @server.read
        assert_equal foobar, message
      end

      # Tests the JSON-RPC example:
      # --> {"jsonrpc": "2.0", "method": "foobar", "id": "1"}
      # <-- {"jsonrpc": "2.0", "error": {"code": -32601, "message": "Method not found"}, "id": "1"}
      def test_method_not_found_error
        foobar = Request.new(method: "foobar")
        @client.write(foobar)

        message = @server.read
        assert_equal foobar, message

        @server.write(message.reply(MethodNotFoundError.new))

        response = @client.read
        assert_instance_of ErrorResponse, response
        assert_equal Error::METHOD_NOT_FOUND, response.error.code
        assert_equal "Method not found", response.error.message
      end

      # Tests the JSON-RPC example:
      # --> {"jsonrpc": "2.0", "method": "foobar, "params": "bar", "baz]
      # <-- {"jsonrpc": "2.0", "error": {"code": -32700, "message": "Parse error"}, "id": null}
      def test_parse_error
        # For parse errors and other invalid messages, we write directly
        # to the socket since the connection object should not readily allow
        # invalid messages to be written.
        @client_socket.write(<<~MESSAGE)
          {"jsonrpc": "2.0", "method": "foobar, "params": "bar", "baz"}
        MESSAGE
        @client_socket.flush

        invalid_message = @server.read
        assert_instance_of InvalidMessage, invalid_message
        assert_equal Error::PARSE_ERROR, invalid_message.error.code
        assert_match(/Parse error/, invalid_message.error.message)
      end

      # Tests the JSON-RPC example:
      # --> {"jsonrpc": "2.0", "method": 1, "params": "bar"}
      # <-- {"jsonrpc": "2.0", "error": {"code": -32600, "message": "Invalid Request"}, "id": null}
      def test_invalid_request_error
        # For "invalid request" errors, we need to send valid JSON but invalid request
        @client_socket.write(<<~MESSAGE)
          {"jsonrpc": "2.0", "method": 1, "params": "bar"}
        MESSAGE
        @client_socket.flush

        invalid_message = @server.read
        assert_instance_of InvalidMessage, invalid_message
        assert_equal Error::INVALID_REQUEST, invalid_message.error.code
        assert_equal "Method must be a string", invalid_message.error.message
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

        invalid_message = @server.read
        assert_instance_of InvalidMessage, invalid_message
        assert_equal Error::PARSE_ERROR, invalid_message.error.code
        assert_match(/Parse error/, invalid_message.error.message)

        response = invalid_message.reply
        @server.write(response)

        response = @client.read
        assert_instance_of ErrorResponse, response
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

        invalid_message = @server.read
        assert_instance_of InvalidMessage, invalid_message
        assert_equal Error::INVALID_REQUEST, invalid_message.error.code
        assert_equal "Invalid Request", invalid_message.error.message

        response = invalid_message.reply
        @server.write(response)

        response = @client.read
        assert_instance_of ErrorResponse, response
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
        assert_instance_of InvalidMessage, messages[0]
        assert_instance_of InvalidRequestError, messages[0].error
        assert_equal Error::INVALID_REQUEST, messages[0].error.code

        response = messages.reply do |message|
          assert false, "invalid messages should not yield"
        end

        @server.write(response)

        response = @client.read
        assert_instance_of Batch, response
        assert_equal 1, response.length
        error_response = response.first

        assert_instance_of ErrorResponse, error_response
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
        assert_instance_of InvalidMessage, messages[0]
        assert_instance_of InvalidRequestError, messages[0].error
        assert_equal Error::INVALID_REQUEST, messages[0].error.code
        assert_instance_of InvalidMessage, messages[1]
        assert_instance_of InvalidRequestError, messages[1].error
        assert_equal Error::INVALID_REQUEST, messages[1].error.code
        assert_instance_of InvalidMessage, messages[2]
        assert_instance_of InvalidRequestError, messages[2].error
        assert_equal Error::INVALID_REQUEST, messages[2].error.code

        response = messages.reply do |message|
          # all invalid, so they will be automatically converted to error responses
        end

        @server.write(response)

        response = @client.read
        assert_equal 3, response.length
        assert_instance_of Batch, response

        response.each do |error_response|
          assert_instance_of ErrorResponse, error_response
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
          Request.new(method: "sum", params: [1, 2, 4], id: "1"),
          Notification.new(method: "notify_hello", params: [7]),
          Request.new(method: "subtract", params: [42, 23], id: "2"),
          {foo: "boo"}, # Invalid request
          Request.new(method: "foo.get", params: {name: "myself"}, id: "5"), # Method not found
          Request.new(method: "get_data", id: "9")
        ]

        @client.write(batch)

        messages = @server.read
        assert_equal 6, messages.length

        sum_received = false
        subtract_received = false
        notification_received = false
        foo_get_received = false
        get_data_received = false

        # Create batch response
        batch_response = messages.reply do |message|
          case message.method
          when "sum"
            sum_received = true
            7
          when "subtract"
            subtract_received = true
            19
          when "notify_hello"
            notification_received = true
          when "foo.get"
            foo_get_received = true
            raise MethodNotFoundError.new("Method not found")
          when "get_data"
            get_data_received = true
            ["hello", 5]
          else
            assert false, "test received unexpected message: #{message.method}"
          end
        end

        assert sum_received, "sum request not received"
        assert subtract_received, "subtract request not received"
        assert notification_received, "notification not received"
        assert foo_get_received, "foo.get request not received"
        assert get_data_received, "get_data request not received"

        @server.write(batch_response)

        response = @client.read
        assert_instance_of Batch, response
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
          Notification.new(method: "notify_sum", params: [1, 2, 4]),
          Notification.new(method: "notify_hello", params: [7])
        ]

        @client.write(batch)

        message = @server.read
        assert_equal 2, message.length
        assert message.all? { |req| req.is_a?(Notification) }

        # No response is expected for notification batches
        # But we can verify the messages were received correctly
        assert_equal "notify_sum", message[0].method
        assert_equal [1, 2, 4], message[0].params
        assert_equal "notify_hello", message[1].method
        assert_equal [7], message[1].params
      end

      def test_read_with_block_yields_message
        request = Request.new(method: "test", params: [1, 2])
        @client.write(request)

        yielded_message = nil
        returned_message = @server.read do |message|
          yielded_message = message
        end

        assert_equal request, yielded_message
        assert_equal request, returned_message
        assert_same yielded_message, returned_message
      end

      def test_read_frame_with_block_yields_frame
        request = Request.new(method: "test", params: [1, 2])
        @client.write(request)

        yielded_frame = nil
        returned_frame = @server.read_frame do |frame|
          yielded_frame = frame
        end

        assert_instance_of Frame, yielded_frame
        assert_instance_of Frame, returned_frame
        assert_same yielded_frame, returned_frame

        # Verify the frame contains the expected data
        message = Message.load(yielded_frame.unpack)
        assert_equal request, message
      end

      def test_close_calls_framer_close
        # Create a mock framer to verify close is called
        mock_framer = Object.new
        close_called = false
        mock_framer.define_singleton_method(:close) { close_called = true }

        connection = Connection.new(mock_framer)
        connection.close

        assert close_called
      end
    end
  end
end
