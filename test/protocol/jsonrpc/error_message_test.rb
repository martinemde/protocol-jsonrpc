# frozen_string_literal: true

require "test_helper"
require "protocol/jsonrpc/error_message"

module Protocol
  module Jsonrpc
    class ErrorResponseTest < Minitest::Test
      def test_initialize_with_required_parameters
        error = { code: -32600, message: "Invalid Request" }
        response = ErrorMessage.new(id: "request_id", error: error)
        assert_equal "request_id", response.id
        assert_equal error, response.error.to_h
      end

      def test_initialize_with_complex_error
        error = {
          code: -32602,
          message: "Invalid params",
          data: {
            details: "Parameter 'id' is required",
            param: "id"
          }
        }
        response = ErrorMessage.new(id: "request_id", error: error)
        assert_equal "request_id", response.id
        assert_equal error, response.error.to_h
      end

      def test_initialize_with_null_id
        error = { code: -32600, message: "Invalid Request" }
        response = ErrorMessage.new(id: nil, error:)
        assert_nil response.id
        assert_equal error, response.error.to_h
      end

      def test_to_h
        error = { code: -32600, message: "Invalid Request" }
        response = ErrorMessage.new(id: "request_id", error: error)
        expected = {
          jsonrpc: "2.0",
          id: "request_id",
          error: { code: -32600, message: "Invalid Request" }
        }
        assert_equal expected, response.to_h
      end

      def test_to_h_with_null_id
        error = { code: -32700, message: "Parse error" }
        response = ErrorMessage.new(id: nil, error: error)
        expected = {
          jsonrpc: "2.0",
          id: nil,
          error: { code: -32700, message: "Parse error" }
        }
        assert_equal expected, response.to_h
      end

      def test_as_json
        error = { code: -32600, message: "Invalid Request" }
        response = ErrorMessage.new(id: "request_id", error: error)
        expected = {
          jsonrpc: "2.0",
          id: "request_id",
          error: { code: -32600, message: "Invalid Request" }
        }
        assert_equal expected, response.as_json
      end

      def test_id_present_with_id
        response = ErrorMessage.new(id: "request_id", error: { code: -32600, message: "Error" })
        assert_equal "request_id", response.id
      end

      def test_id_present_with_nil_id
        response = ErrorMessage.new(id: nil, error: { code: -32600, message: "Error" })
        assert_nil response.id
      end

      def test_as_json
        error = { code: -32600, message: "Invalid Request" }
        response = ErrorMessage.new(id: "request_id", error: error)
        expected = {
          jsonrpc: "2.0",
          id: "request_id",
          error: { code: -32600, message: "Invalid Request" }
        }
        assert_equal expected, response.as_json
      end
    end
  end
end
