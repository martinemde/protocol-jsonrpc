# frozen_string_literal: true

# Released under the MIT License.
# Copyright 2025 by Martin Emde

require "test_helper"
require "protocol/jsonrpc"
require "protocol/jsonrpc/message"
require "protocol/jsonrpc/error"

module Protocol
  module Jsonrpc
    class MessageTest < Minitest::Test
      def test_parse_valid_request
        json = { jsonrpc: "2.0", id: "123", method: "test_method", params: { foo: "bar" } }
        message = Message.load(json)

        assert_instance_of RequestMessage, message
        assert_equal "123", message.id
        assert_equal "test_method", message.method
        assert_equal({ foo: "bar" }, message.params)
      end

      def test_parse_valid_notification
        json = { jsonrpc: "2.0", method: "test_notification" }
        message = Message.load(json)

        assert_instance_of NotificationMessage, message
        assert_equal "test_notification", message.method
        assert_nil message.params
        assert_nil message.id
      end

      def test_parse_valid_response
        json = { jsonrpc: "2.0", id: "123", result: { status: "success" } }
        message = Message.load(json)

        assert_instance_of ResponseMessage, message
        assert_equal "123", message.id
        assert_equal({ status: "success" }, message.result)
      end

      def test_parse_valid_error_response
        json = { jsonrpc: "2.0", id: "123", error: { code: -32600, message: "Invalid Request" } }
        message = Message.load(json)

        assert_instance_of ErrorMessage, message
        assert_equal "123", message.id
        assert_equal({ code: -32600, message: "Invalid Request" }, message.error.to_h)
      end

      def test_parse_valid_error_response_with_nil_id
        json = { jsonrpc: "2.0", id: nil, error: { code: -32600, message: "Invalid Request" } }
        message = Message.load(json)

        assert_instance_of ErrorMessage, message
        assert_nil message.id
        assert_equal({ code: -32600, message: "Invalid Request" }, message.error.to_h)
      end

      def test_parse_valid_batch_request
        json = [
          { jsonrpc: "2.0", id: "123", method: "test_method", params: { foo: "bar" } },
          { jsonrpc: "2.0", id: "456", method: "test_method", params: { foo: "bar" } }
        ]
        messages = Message.load(json)

        assert_equal 2, messages.size
        assert_instance_of RequestMessage, messages.first
        assert_instance_of RequestMessage, messages.last
      end

      def test_parse_valid_batch_response
        json = [
          { jsonrpc: "2.0", id: "123", result: { status: "success" } },
          { jsonrpc: "2.0", id: "456", result: { status: "success" } }
        ]
        messages = Message.load(json)

        assert_equal 2, messages.size
        assert_instance_of ResponseMessage, messages.first
        assert_instance_of ResponseMessage, messages.last
      end

      def test_parse_valid_batch_mixed_response_and_error_response
        json = [
          { jsonrpc: "2.0", id: "123", result: { status: "success" } },
          { jsonrpc: "2.0", id: nil, error: { code: -32600, message: "Invalid request" } }
        ]
        messages = Message.load(json)

        assert_equal 2, messages.size
        assert_instance_of ResponseMessage, messages.first
        assert_instance_of ErrorMessage, messages.last
      end

      def test_invalid_jsonrpc_version
        json = { jsonrpc: "1.0", id: "123", method: "test_method" }
        error = assert_raises(InvalidRequestError) do
          Message.load(json)
        end
        assert_match(/Unexpected JSON-RPC version/, error.message)
      end

      def test_invalid_request_object
        json = "not an object"
        error = assert_raises(InvalidRequestError) do
          Message.load(json)
        end
        assert_match(/Invalid request object/, error.message)
      end
    end
  end
end
