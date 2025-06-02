# frozen_string_literal: true

# Released under the MIT License.
# Copyright 2025 by Martin Emde

require "test_helper"

module Protocol
  module Jsonrpc
    class BatchTest < Minitest::Test
      def assert_json_equal(data, actual)
        assert_equal(data, JSON.parse(actual, symbolize_names: true))
      end

      def test_load_empty_array_returns_invalid_message
        data = []
        result = Batch.load(data)

        assert_instance_of InvalidMessage, result
        assert_equal "[]", result.error.data
        assert_instance_of InvalidRequestError, result.error
      end

      def test_load_valid_batch_with_requests
        data = [
          {jsonrpc: "2.0", id: "1", method: "sum", params: [1, 2, 3]},
          {jsonrpc: "2.0", id: "2", method: "subtract", params: [10, 5]}
        ]
        batch = Batch.load(data)

        assert_instance_of Batch, batch
        assert_equal 2, batch.messages.size
        assert_instance_of Request, batch.messages[0]
        assert_instance_of Request, batch.messages[1]
        assert_equal "1", batch.messages[0].id
        assert_equal "2", batch.messages[1].id
        assert_equal "sum", batch.messages[0].method
        assert_equal "subtract", batch.messages[1].method
      end

      def test_load_valid_batch_with_notifications
        data = [
          {jsonrpc: "2.0", method: "notify_hello", params: [7]},
          {jsonrpc: "2.0", method: "notify_world"}
        ]
        batch = Batch.load(data)

        assert_instance_of Batch, batch
        assert_equal 2, batch.messages.size
        assert_instance_of Notification, batch.messages[0]
        assert_instance_of Notification, batch.messages[1]
        assert_equal "notify_hello", batch.messages[0].method
        assert_equal "notify_world", batch.messages[1].method
      end

      def test_load_valid_batch_with_responses
        data = [
          {jsonrpc: "2.0", id: "1", result: 42},
          {jsonrpc: "2.0", id: "2", result: "success"}
        ]
        batch = Batch.load(data)

        assert_instance_of Batch, batch
        assert_equal 2, batch.messages.size
        assert_instance_of Response, batch.messages[0]
        assert_instance_of Response, batch.messages[1]
        assert_equal "1", batch.messages[0].id
        assert_equal "2", batch.messages[1].id
        assert_equal 42, batch.messages[0].result
        assert_equal "success", batch.messages[1].result
      end

      def test_load_valid_batch_with_error_responses
        data = [
          {jsonrpc: "2.0", id: "1", error: {code: -32601, message: "Method not found"}},
          {jsonrpc: "2.0", id: nil, error: {code: -32600, message: "Invalid Request"}}
        ]
        batch = Batch.load(data)

        assert_instance_of Batch, batch
        assert_equal 2, batch.messages.size
        assert_instance_of ErrorResponse, batch.messages[0]
        assert_instance_of ErrorResponse, batch.messages[1]
        assert_equal "1", batch.messages[0].id
        assert_nil batch.messages[1].id
        assert_equal(-32601, batch.messages[0].error.code)
        assert_equal(-32600, batch.messages[1].error.code)
      end

      def test_load_batch_with_mixed_message_types
        data = [
          {jsonrpc: "2.0", id: "1", method: "sum", params: [1, 2]},
          {jsonrpc: "2.0", method: "notify_hello"},
          {jsonrpc: "2.0", id: "2", result: 42},
          {jsonrpc: "2.0", id: "3", error: {code: -32601, message: "Method not found"}}
        ]
        batch = Batch.load(data)

        assert_instance_of Batch, batch
        assert_equal 4, batch.messages.size
        assert_instance_of Request, batch.messages[0]
        assert_instance_of Notification, batch.messages[1]
        assert_instance_of Response, batch.messages[2]
        assert_instance_of ErrorResponse, batch.messages[3]
      end

      def test_load_batch_with_invalid_messages
        data = [
          {jsonrpc: "2.0", id: "1", method: "sum", params: [1, 2]},
          "invalid",
          42,
          {jsonrpc: "2.0", method: "notify_hello"}
        ]
        batch = Batch.load(data)

        assert_instance_of Batch, batch
        assert_equal 4, batch.messages.size
        assert_instance_of Request, batch.messages[0]
        assert_instance_of InvalidMessage, batch.messages[1]
        assert_instance_of InvalidMessage, batch.messages[2]
        assert_instance_of Notification, batch.messages[3]
        assert_equal %("invalid"), batch.messages[1].error.data
        assert_equal "42", batch.messages[2].error.data
      end

      def test_to_a_returns_messages_array
        messages = [
          Request.new(id: "1", method: "test"),
          Notification.new(method: "notify")
        ]
        batch = Batch.new(messages)

        assert_equal messages, batch.to_a
        assert_same messages, batch.to_a
      end

      def test_to_ary_alias
        messages = [Request.new(id: "1", method: "test")]
        batch = Batch.new(messages)

        assert_equal messages, batch.to_ary
        assert_same batch.to_a, batch.to_ary
      end

      def test_as_json_returns_array_of_message_json
        messages = [
          Request.new(id: "1", method: "sum", params: [1, 2]),
          Notification.new(method: "notify_hello", params: [7])
        ]
        batch = Batch.new(messages)
        expected = [
          {jsonrpc: "2.0", id: "1", method: "sum", params: [1, 2]},
          {jsonrpc: "2.0", method: "notify_hello", params: [7]}
        ]

        assert_equal expected, batch.as_json
      end

      def test_to_json_generates_json_string
        messages = [
          Request.new(id: "1", method: "sum", params: [1, 2]),
          Notification.new(method: "notify_hello")
        ]
        batch = Batch.new(messages)
        expected = [
          {jsonrpc: "2.0", id: "1", method: "sum", params: [1, 2]},
          {jsonrpc: "2.0", method: "notify_hello"}
        ]

        assert_json_equal expected, batch.to_json
      end

      def test_to_json_with_options
        messages = [Request.new(id: "1", method: "test")]
        batch = Batch.new(messages)

        # Test that options are passed through to JSON.generate
        result = batch.to_json(indent: "  ")
        assert_includes result, "  "
      end

      def test_to_s_alias_for_to_json
        messages = [Request.new(id: "1", method: "test")]
        batch = Batch.new(messages)

        assert_equal batch.to_json, batch.to_s
      end

      def test_reply_with_block_filters_responses
        messages = [
          Request.new(id: "1", method: "sum", params: [1, 2]),
          Notification.new(method: "notify_hello"),
          Request.new(id: "2", method: "multiply", params: [3, 4])
        ]
        batch = Batch.new(messages)

        responses = batch.reply do |message|
          case message.method
          when "sum"
            message.params.sum
          when "multiply"
            message.params.reduce(:*)
          when "notify_hello"
            # Notifications don't return responses
            nil
          end
        end

        assert_equal 2, responses.size
        assert_instance_of Response, responses[0]
        assert_instance_of Response, responses[1]
        assert_equal "1", responses[0].id
        assert_equal "2", responses[1].id
        assert_equal 3, responses[0].result
        assert_equal 12, responses[1].result
      end

      def test_reply_with_block_handles_errors
        messages = [
          Request.new(id: "1", method: "divide", params: [10, 0]),
          Request.new(id: "2", method: "sum", params: [1, 2])
        ]
        batch = Batch.new(messages)

        responses = batch.reply do |message|
          case message.method
          when "divide"
            raise "Division by zero"
          when "sum"
            message.params.sum
          end
        end

        assert_equal 2, responses.size
        assert_instance_of ErrorResponse, responses[0]
        assert_instance_of Response, responses[1]
        assert_equal "1", responses[0].id
        assert_equal "2", responses[1].id
        assert_instance_of InternalError, responses[0].error
        assert_equal 3, responses[1].result
      end

      def test_reply_with_invalid_messages
        messages = [
          Request.new(id: "1", method: "sum", params: [1, 2]),
          InvalidMessage.new(data: "invalid")
        ]
        batch = Batch.new(messages)

        responses = batch.reply do |message|
          case message
          when Request
            message.params.sum
          when InvalidMessage
            # InvalidMessage.reply doesn't call the block
            nil
          end
        end

        assert_equal 2, responses.size
        assert_instance_of Response, responses[0]
        assert_instance_of ErrorResponse, responses[1]
        assert_equal "1", responses[0].id
        assert_equal 3, responses[0].result
        assert_instance_of InvalidRequestError, responses[1].error
      end

      def test_method_missing_delegates_to_messages
        messages = [
          Request.new(id: "1", method: "test"),
          Request.new(id: "2", method: "test")
        ]
        batch = Batch.new(messages)

        # Test delegation of Array methods
        assert_equal 2, batch.size
        assert_equal 2, batch.length
        assert_equal 2, batch.count
        assert_equal messages[0], batch.first
        assert_equal messages[1], batch.last
        assert_equal messages, batch.map(&:itself)
      end

      def test_method_missing_with_block_delegation
        messages = [
          Request.new(id: "1", method: "sum"),
          Request.new(id: "2", method: "multiply")
        ]
        batch = Batch.new(messages)

        methods = batch.map(&:method)
        assert_equal ["sum", "multiply"], methods
      end

      def test_method_missing_with_arguments_and_kwargs
        messages = [Request.new(id: "1", method: "test")]
        batch = Batch.new(messages)

        # Test slice method with arguments
        result = batch.slice(0, 1)
        assert_equal [messages[0]], result
      end

      def test_method_missing_raises_for_unknown_methods
        messages = [Request.new(id: "1", method: "test")]
        batch = Batch.new(messages)

        assert_raises(NoMethodError) do
          batch.unknown_method
        end
      end

      def test_respond_to_missing_returns_true_for_delegated_methods
        messages = [Request.new(id: "1", method: "test")]
        batch = Batch.new(messages)

        assert batch.respond_to?(:size)
        assert batch.respond_to?(:length)
        assert batch.respond_to?(:first)
        assert batch.respond_to?(:map)
        assert batch.respond_to?(:each)
      end

      def test_respond_to_missing_returns_false_for_unknown_methods
        messages = [Request.new(id: "1", method: "test")]
        batch = Batch.new(messages)

        refute batch.respond_to?(:unknown_method)
      end

      def test_respond_to_missing_with_include_private
        messages = [Request.new(id: "1", method: "test")]
        batch = Batch.new(messages)

        # Test that include_private is passed through
        assert batch.respond_to?(:size, true)
        refute batch.respond_to?(:unknown_method, true)
      end

      def test_array_like_behavior_with_indexing
        messages = [
          Request.new(id: "1", method: "first"),
          Request.new(id: "2", method: "second")
        ]
        batch = Batch.new(messages)

        assert_equal messages[0], batch[0]
        assert_equal messages[1], batch[1]
        assert_nil batch[2]
      end

      def test_enumerable_behavior
        messages = [
          Request.new(id: "1", method: "sum"),
          Request.new(id: "2", method: "multiply")
        ]
        batch = Batch.new(messages)

        # Test that we can iterate
        collected = []
        batch.each { |msg| collected << msg }
        assert_equal messages, collected

        # Test other enumerable methods
        assert_equal 2, batch.count
        assert batch.all? { |msg| msg.is_a?(Request) }
        assert batch.any? { |msg| msg.method == "sum" }
      end
    end
  end
end
