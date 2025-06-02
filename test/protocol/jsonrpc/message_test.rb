# frozen_string_literal: true

# Released under the MIT License.
# Copyright 2025 by Martin Emde

require "test_helper"

module Protocol
  module Jsonrpc
    class MessageTest < Minitest::Test
      def assert_json_equal(data, actual)
        assert_equal(data, JSON.parse(actual, symbolize_names: true))
      end

      def test_load_valid_request
        data = {jsonrpc: "2.0", id: "123", method: "test_method", params: {foo: "bar"}}
        message = Message.load(data)

        assert_instance_of Request, message
        assert_equal "123", message.id
        assert_equal "test_method", message.method
        assert_equal({foo: "bar"}, message.params)
        assert_equal(data, message.as_json)
        assert_equal(data, message.to_h)
        assert_json_equal(data, message.to_json)
        assert_json_equal(data, message.to_s)
      end

      def test_load_valid_notification
        data = {jsonrpc: "2.0", method: "test_notification"}
        message = Message.load(data)

        assert_instance_of Notification, message
        assert_equal "test_notification", message.method
        assert_nil message.params
        assert_nil message.id
        assert_equal(data, message.as_json)
        assert_equal(data, message.to_h)
        assert_json_equal(data, message.to_json)
        assert_json_equal(data, message.to_s)
      end

      def test_load_valid_response
        data = {jsonrpc: "2.0", id: "123", result: {status: "success"}}
        message = Message.load(data)

        assert_instance_of Response, message
        assert_equal "123", message.id
        assert_equal({status: "success"}, message.result)
        assert_equal(data, message.as_json)
        assert_equal(data, message.to_h)
        assert_json_equal(data, message.to_json)
        assert_json_equal(data, message.to_s)
      end

      def test_load_valid_error_response
        data = {jsonrpc: "2.0", id: "123", error: {code: -32600, message: "Invalid Request"}}
        message = Message.load(data)

        assert_instance_of ErrorResponse, message
        assert_equal "123", message.id
        assert_equal({code: -32600, message: "Invalid Request"}, message.error.to_h)
        assert_equal(data, message.as_json)
        assert_equal(data, message.to_h)
        assert_json_equal(data, message.to_json)
        assert_json_equal(data, message.to_s)
      end

      def test_load_valid_error_response_with_nil_id
        data = {jsonrpc: "2.0", id: nil, error: {code: -32600, message: "Invalid Request"}}
        message = Message.load(data)

        assert_instance_of ErrorResponse, message
        assert_nil message.id
        assert_equal({code: -32600, message: "Invalid Request"}, message.error.to_h)
        assert_equal(data, message.as_json)
        assert_equal(data, message.to_h)
        assert_json_equal(data, message.to_json)
        assert_json_equal(data, message.to_s)
      end

      def test_load_invalid_message
        data = 1
        message = Message.load(data)

        assert_instance_of InvalidMessage, message
        assert_equal "1", message.error.data
        assert_instance_of InvalidRequestError, message.error
        assert_equal "Invalid Request", message.error.message
      end

      def test_load_invalid_request_object
        data = "not an object"
        message = Message.load(data)
        assert_instance_of InvalidMessage, message
        assert_equal %("not an object"), message.error.data
        assert_instance_of InvalidRequestError, message.error
      end

      def test_load_empty_batch
        data = []
        message = Message.load(data)

        assert_instance_of InvalidMessage, message
        assert_equal "[]", message.error.data
        assert_instance_of InvalidRequestError, message.error
        assert_equal "Invalid Request", message.error.message
      end

      def test_load_invalid_batch_but_not_empty
        data = [1]
        messages = Message.load(data)

        assert_equal 1, messages.size
        assert_instance_of InvalidMessage, messages[0]
        assert_equal "1", messages[0].error.data
        assert_instance_of InvalidRequestError, messages[0].error
        assert_equal "Invalid Request", messages[0].error.message
      end

      def test_load_invalid_batch
        data = [1, 2, 3]
        messages = Message.load(data)

        assert_equal 3, messages.size
        assert_instance_of InvalidMessage, messages[0]
        assert_equal "1", messages[0].error.data
        assert_instance_of InvalidRequestError, messages[0].error
        assert_equal "Invalid Request", messages[0].error.message
        assert_instance_of InvalidMessage, messages[1]
        assert_equal "2", messages[1].error.data
        assert_instance_of InvalidRequestError, messages[1].error
        assert_equal "Invalid Request", messages[1].error.message
        assert_instance_of InvalidMessage, messages[2]
        assert_equal "3", messages[2].error.data
        assert_instance_of InvalidRequestError, messages[2].error
        assert_equal "Invalid Request", messages[2].error.message
      end

      def test_load_valid_batch_request
        data = [
          {jsonrpc: "2.0", id: "123", method: "test_method", params: {foo: "bar"}},
          {jsonrpc: "2.0", id: "456", method: "test_method", params: {foo: "bar"}}
        ]
        messages = Message.load(data)

        assert_equal 2, messages.size
        assert_instance_of Request, messages[0]
        assert_instance_of Request, messages[1]
        assert_json_equal(data, messages.map(&:as_json).to_json)
      end

      def test_load_valid_batch_response
        data = [
          {jsonrpc: "2.0", id: "123", result: {status: "success"}},
          {jsonrpc: "2.0", id: "456", result: {status: "success"}}
        ]
        messages = Message.load(data)

        assert_equal 2, messages.size
        assert_instance_of Response, messages[0]
        assert_instance_of Response, messages[1]
        assert_json_equal(data, messages.map(&:as_json).to_json)
      end

      def test_load_valid_batch_mixed_response_and_error_response
        data = [
          {jsonrpc: "2.0", id: "123", result: {status: "success"}},
          {jsonrpc: "2.0", id: nil, error: {code: -32600, message: "Invalid Request"}}
        ]
        messages = Message.load(data)

        assert_equal 2, messages.size
        assert_instance_of Response, messages[0]
        assert_instance_of ErrorResponse, messages[1]
        assert_json_equal(data, messages.map(&:as_json).to_json)
      end

      def test_load_old_jsonrpc_without_version
        data = {id: "123", method: "test_method"}
        message = Message.load(data)
        assert_instance_of Request, message
        assert_equal "123", message.id
        assert_equal "test_method", message.method
        assert_nil message.params
      end

      def test_from_hash_with_non_hash_returns_invalid_message
        # Test the guard clause that checks if parsed is a Hash
        message = Message.from_hash("not a hash")

        assert_instance_of InvalidMessage, message
        assert_equal %("not a hash"), message.error.data
        assert_instance_of InvalidRequestError, message.error
      end
    end
  end
end
