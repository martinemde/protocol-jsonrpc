# frozen_string_literal: true

# Released under the MIT License.
# Copyright 2025 by Martin Emde

require "test_helper"

module Protocol
  module Jsonrpc
    class ErrorTest < Minitest::Test
      def test_error_constants
        assert_equal(-32_700, Error::PARSE_ERROR)
        assert_equal(-32_600, Error::INVALID_REQUEST)
        assert_equal(-32_601, Error::METHOD_NOT_FOUND)
        assert_equal(-32_602, Error::INVALID_PARAMS)
        assert_equal(-32_603, Error::INTERNAL_ERROR)
      end

      def test_error_responses
        assert_equal("Parse error", Error::ERROR_MESSAGES[Error::PARSE_ERROR])
        assert_equal("Invalid Request", Error::ERROR_MESSAGES[Error::INVALID_REQUEST])
        assert_equal("Method not found", Error::ERROR_MESSAGES[Error::METHOD_NOT_FOUND])
        assert_equal("Invalid params", Error::ERROR_MESSAGES[Error::INVALID_PARAMS])
        assert_equal("Internal error", Error::ERROR_MESSAGES[Error::INTERNAL_ERROR])
        assert_equal("Error", Error::ERROR_MESSAGES[12345]) # Default message
      end

      def test_parse_error_creation
        error = Error.from_message(code: Error::PARSE_ERROR, message: "Parse error")
        assert_instance_of(ParseError, error)
        assert_equal("Parse error", error.message)
      end

      def test_invalid_request_error_creation
        error = Error.from_message(code: Error::INVALID_REQUEST, message: "Missing required parameter")
        assert_instance_of(InvalidRequestError, error)
        assert_equal("Missing required parameter", error.message)
      end

      def test_method_not_found_error_creation
        error = Error.from_message(code: Error::METHOD_NOT_FOUND, message: "Unknown method fart")
        assert_instance_of(MethodNotFoundError, error)
        assert_equal("Unknown method fart", error.message)
      end

      def test_invalid_params_error_creation
        error = Error.from_message(code: Error::INVALID_PARAMS, message: "1 is not a valid parameter")
        assert_instance_of(InvalidParamsError, error)
        assert_equal("1 is not a valid parameter", error.message)
      end

      def test_internal_error_creation
        error = Error.from_message(code: Error::INTERNAL_ERROR, message: "KeyError: key not found")
        assert_instance_of(InternalError, error)
        assert_equal("KeyError: key not found", error.message)
      end

      def test_generic_error_creation
        error = Error.from_message(code: -99999, message: "Custom error")
        assert_instance_of(Error, error)
        assert_equal("Custom error", error.message)
      end

      def test_error_with_data
        data = {details: "Additional information"}
        error = Error.from_message(code: Error::INTERNAL_ERROR, message: "Error", data:)

        assert_equal(data, error.data)
        assert_equal({code: Error::INTERNAL_ERROR, message: "Error", data: data}, error.to_h)
      end

      def test_reply
        error = ParseError.new("Test error", data: {details: "info"})
        response = error.reply

        assert_instance_of(Jsonrpc::ErrorResponse, response)
        assert_nil response.id
        assert_equal(Error::PARSE_ERROR, response.error.code)
        assert_equal("Test error", response.error.message)
        assert_equal({details: "info"}, response.error.data)
      end

      def test_reply_with_id
        error = ParseError.new("Test error", data: {details: "info"}, id: "req-123")
        response = error.reply

        assert_instance_of(Jsonrpc::ErrorResponse, response)
        assert_equal("req-123", response.id)
        assert_equal(Error::PARSE_ERROR, response.error.code)
        assert_equal("Test error", response.error.message)
        assert_equal({details: "info"}, response.error.data)
      end

      def test_reply_with_id_arg
        error = ParseError.new("Test error", data: {details: "info"}, id: "req-123")
        response = error.reply(id: "req-456")

        assert_instance_of(Jsonrpc::ErrorResponse, response)
        assert_equal("req-456", response.id)
      end

      def test_parse_error_code
        error = ParseError.new("Parse error")
        assert_equal(Error::PARSE_ERROR, error.code)
      end

      def test_invalid_request_error_code
        error = InvalidRequestError.new("Invalid request")
        assert_equal(Error::INVALID_REQUEST, error.code)
      end

      def test_method_not_found_error_code
        error = MethodNotFoundError.new("Method not found")
        assert_equal(Error::METHOD_NOT_FOUND, error.code)
      end

      def test_invalid_params_error_code
        error = InvalidParamsError.new("Invalid params")
        assert_equal(Error::INVALID_PARAMS, error.code)
      end

      def test_internal_error_code
        error = InternalError.new("Internal error")
        assert_equal(Error::INTERNAL_ERROR, error.code)
      end
    end
  end
end
