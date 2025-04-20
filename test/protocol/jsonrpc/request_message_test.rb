# frozen_string_literal: true

require "test_helper"
require "protocol/jsonrpc/request_message"

module Protocol
  module Jsonrpc
    class RequestTest < Minitest::Test
      def test_with_required_parameters
        request = RequestMessage.new(method: "test_method")
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
        request = RequestMessage.new(
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
        request = RequestMessage.new(
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
          RequestMessage.new(method: "test_method", id: nil)
        end
        assert_match(/ID must be a string or number/, error.message)
      end

      def test_id
        request = RequestMessage.new(method: "test_method")
        refute_nil request.id
      end

      def test_empty_params
        request = RequestMessage.new(method: "test_method", params: [])
        assert_equal [], request.to_h[:params]

        request = RequestMessage.new(method: "test_method", params: {})
        assert_equal({}, request.to_h[:params])
      end

      def test_invalid_method
        error = assert_raises(InvalidRequestError) do
          RequestMessage.new(method: 123)
        end
        assert_match(/Method must be a string/, error.message)
      end

      def test_invalid_params
        error = assert_raises(InvalidRequestError) do
          RequestMessage.new(method: "test_method", params: "invalid")
        end
        assert_match(/Params must be an array or object/, error.message)
      end
    end
  end
end
