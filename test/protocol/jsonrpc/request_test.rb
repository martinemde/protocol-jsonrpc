# frozen_string_literal: true

require "test_helper"

module Protocol
  module Jsonrpc
    class RequestTest < Minitest::Test
      def test_with_required_parameters
        request = Request.new(method: "test_method")
        assert_equal "test_method", request.method
        assert_nil request.params
        refute_nil request.id

        expected = {
          jsonrpc: "2.0",
          id: request.id,
          method: "test_method"
        }
        assert_equal expected, request.to_h
        assert_equal expected, request.as_json
      end

      def test_with_all_parameters
        request = Request.new(
          method: "test_method",
          params: {foo: "bar"},
          id: "custom_id"
        )
        assert_equal "test_method", request.method
        assert_equal({foo: "bar"}, request.params)
        assert_equal "custom_id", request.id

        expected = {
          jsonrpc: "2.0",
          id: "custom_id",
          method: "test_method",
          params: {foo: "bar"}
        }
        assert_equal expected, request.to_h
        assert_equal expected, request.as_json
      end

      def test_with_array_params
        request = Request.new(
          method: "test_method",
          params: [1, 2, 3],
          id: "custom_id"
        )
        assert_equal "test_method", request.method
        assert_equal [1, 2, 3], request.params
        assert_equal "custom_id", request.id

        expected = {
          jsonrpc: "2.0",
          id: "custom_id",
          method: "test_method",
          params: [1, 2, 3]
        }
        assert_equal expected, request.to_h
        assert_equal expected, request.as_json
      end

      def test_raises_on_nil_id
        error = assert_raises(InvalidRequestError) do
          Request.new(method: "test_method", id: nil)
        end
        assert_match(/ID must be a string or number/, error.message)
      end

      def test_id
        request = Request.new(method: "test_method")
        refute_nil request.id
      end

      def test_empty_params
        request = Request.new(method: "test_method", params: [])
        assert_equal [], request.to_h[:params]

        request = Request.new(method: "test_method", params: {})
        assert_equal({}, request.to_h[:params])
      end

      def test_invalid_method
        error = assert_raises(InvalidRequestError) do
          Request.new(method: 123)
        end
        assert_match(/Method must be a string/, error.message)
      end

      def test_invalid_params
        error = assert_raises(InvalidRequestError) do
          Request.new(method: "test_method", params: "invalid")
        end
        assert_match(/Params must be an array or object/, error.message)
      end

      def test_reply_with_object
        request = Request.new(method: "answer/the", params: ["life", "universe", "everything"])
        response = request.reply(42)
        assert_instance_of Response, response
        assert_equal request.id, response.id
        assert_equal 42, response.result
      end

      def test_reply_with_block
        request = Request.new(method: "answer/the", params: ["life", "universe", "everything"])
        response = request.reply { 42 }
        assert_instance_of Response, response
        assert_equal request.id, response.id
        assert_equal 42, response.result
      end

      def test_reply_with_block_that_raises_error
        request = Request.new(method: "question/the", params: ["life", "universe", "everything"])
        response = request.reply { raise "Insufficient data" }
        assert_instance_of ErrorResponse, response
        assert_equal request.id, response.id
        assert_equal "Insufficient data", response.error.message
      end

      def test_reply_with_block_that_raises_jsonrpc_error
        request = Request.new(method: "try")
        response = request.reply { raise Protocol::Jsonrpc::MethodNotFoundError, "Supported methods: do, do_not" }
        assert_instance_of ErrorResponse, response
        assert_equal request.id, response.id
        assert_instance_of MethodNotFoundError, response.error
        assert_equal "Supported methods: do, do_not", response.error.message
      end

      def test_reply_with_block_that_raises_jsonrpc_error_with_data
        request = Request.new(method: "try")
        response = request.reply { raise Protocol::Jsonrpc::MethodNotFoundError.new("Supported methods: do, do_not", data: {methods: ["do", "do_not"]}) }
        assert_instance_of ErrorResponse, response
        assert_equal request.id, response.id
        assert_instance_of MethodNotFoundError, response.error
        assert_equal "Supported methods: do, do_not", response.error.message
        assert_equal({methods: ["do", "do_not"]}, response.error.data)
      end

      def test_reply_with_too_many_arguments
        request = Request.new(method: "answer/the", params: ["life", "universe", "everything"])
        assert_raises(ArgumentError) do
          request.reply(42, 43)
        end
      end
    end
  end
end
