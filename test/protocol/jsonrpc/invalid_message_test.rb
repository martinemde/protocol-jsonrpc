# frozen_string_literal: true

# Released under the MIT License.
# Copyright 2025 by Martin Emde

require "test_helper"

module Protocol
  module Jsonrpc
    class InvalidMessageTest < Minitest::Test
      def test_initialize_with_error_object
        error = ParseError.new("Parse error", id: "req-123")
        invalid_message = InvalidMessage.new(error: error, id: "req-123")

        assert_instance_of InvalidMessage, invalid_message
        assert_equal error, invalid_message.error
        assert_equal "req-123", invalid_message.id
      end

      def test_initialize_with_hash_error
        error_hash = {code: -32600, message: "Invalid Request"}
        invalid_message = InvalidMessage.new(error: error_hash, id: "req-456")

        assert_instance_of InvalidRequestError, invalid_message.error
        assert_equal(-32600, invalid_message.error.code)
        assert_equal "Invalid Request", invalid_message.error.message
        assert_equal "req-456", invalid_message.id
      end

      def test_initialize_with_string_error
        invalid_message = InvalidMessage.new(error: "Something went wrong", id: "req-789")

        assert_instance_of InternalError, invalid_message.error
        assert_equal "Something went wrong", invalid_message.error.message
        assert_equal "req-789", invalid_message.id
      end

      def test_initialize_with_data_parameter
        invalid_message = InvalidMessage.new(
          error: "Custom error",
          data: {details: "Additional info"},
          id: "req-data"
        )

        assert_instance_of InternalError, invalid_message.error
        assert_equal "Custom error", invalid_message.error.message
        assert_equal({details: "Additional info"}, invalid_message.error.data)
        assert_equal "req-data", invalid_message.id
      end

      def test_initialize_uses_error_id_when_no_id_provided
        error = InvalidRequestError.new("Bad request", id: "error-id")
        invalid_message = InvalidMessage.new(error: error)

        assert_instance_of InvalidRequestError, invalid_message.error
        assert_equal "error-id", invalid_message.id
      end

      def test_initialize_with_nil_values
        invalid_message = InvalidMessage.new

        assert_instance_of InvalidRequestError, invalid_message.error
        assert_nil invalid_message.id
      end

      def test_reply_creates_error_response
        error = ParseError.new("Parse error", id: "req-123")
        invalid_message = InvalidMessage.new(error: error)
        response = invalid_message.reply

        assert_instance_of ErrorResponse, response
        assert_equal "req-123", response.id
        assert_equal error, response.error
      end

      def test_reply_ignores_arguments
        invalid_message = InvalidMessage.new(error: "Test error", id: "req-123")
        response = invalid_message.reply("result")

        assert_instance_of ErrorResponse, response
        assert_equal "req-123", response.id
        assert_equal invalid_message.error, response.error
        assert_equal "Test error", response.error.message
      end

      def test_reply_with_block
        invalid_message = InvalidMessage.new(error: "Parse error")
        response = invalid_message.reply { raise "InvalidMessage#reply should call the block" }

        assert_instance_of ErrorResponse, response
        assert_nil response.id
        assert_equal invalid_message.error, response.error
      end
    end
  end
end
