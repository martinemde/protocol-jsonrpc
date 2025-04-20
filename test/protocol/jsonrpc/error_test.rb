# frozen_string_literal: true

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

      def test_error_messages
        assert_equal("Parse error", Error::MESSAGES[Error::PARSE_ERROR])
        assert_equal("Invalid Request", Error::MESSAGES[Error::INVALID_REQUEST])
        assert_equal("Method not found", Error::MESSAGES[Error::METHOD_NOT_FOUND])
        assert_equal("Invalid params", Error::MESSAGES[Error::INVALID_PARAMS])
        assert_equal("Internal error", Error::MESSAGES[Error::INTERNAL_ERROR])
        assert_equal("Error", Error::MESSAGES[12345]) # Default message
      end

      def test_error_factory_method
        # Test ParseError creation
        error = Error.from_message(code: Error::PARSE_ERROR, message: "Parse error")
        assert_instance_of(ParseError, error)
        assert_equal("Parse error", error.message)

        # Test InvalidRequestError creation
        error = Error.from_message(code: Error::INVALID_REQUEST, message: "Missing required parameter")
        assert_instance_of(InvalidRequestError, error)
        assert_equal("Invalid Request: Missing required parameter", error.message)

        # Test MethodNotFoundError creation
        error = Error.from_message(code: Error::METHOD_NOT_FOUND, message: "Unknown method fart")
        assert_instance_of(MethodNotFoundError, error)
        assert_equal("Method not found: Unknown method fart", error.message)

        # Test InvalidParamsError creation
        error = Error.from_message(code: Error::INVALID_PARAMS, message: "1 is not a valid parameter")
        assert_instance_of(InvalidParamsError, error)
        assert_equal("Invalid params: 1 is not a valid parameter", error.message)

        # Test InternalError creation
        error = Error.from_message(code: Error::INTERNAL_ERROR, message: "KeyError: key not found")
        assert_instance_of(InternalError, error)
        assert_equal("Internal error: KeyError: key not found", error.message)

        # Test generic error creation
        error = Error.from_message(code: -99999, message: "Custom error")
        assert_instance_of(Error, error)
        assert_equal("Error: Custom error", error.message)
      end

      def test_error_with_data
        data = { details: "Additional information" }
        error = Error.from_message(code: Error::INTERNAL_ERROR, message: "Error", data:)

        assert_equal(data, error.data)
        assert_equal({ code: Error::INTERNAL_ERROR, message: "Internal error: Error", data: data }, error.to_h)
      end

      def test_reply
        error = ParseError.new("Test error", data: { details: "info" })
        response = error.reply

        assert_instance_of(Jsonrpc::ErrorMessage, response)
        assert_nil response.id
        assert_equal(Error::PARSE_ERROR, response.error.code)
        assert_equal("Parse error: Test error", response.error.message)
        assert_equal({ details: "info" }, response.error.data)
      end

      def test_reply_with_id
        error = ParseError.new("Test error", data: { details: "info" }, id: "req-123")
        response = error.reply

        assert_instance_of(Jsonrpc::ErrorMessage, response)
        assert_equal("req-123", response.id)
        assert_equal(Error::PARSE_ERROR, response.error.code)
        assert_equal("Parse error: Test error", response.error.message)
        assert_equal({ details: "info" }, response.error.data)
      end

      def test_reply_with_id_arg
        error = ParseError.new("Test error", data: { details: "info" }, id: "req-123")
        response = error.reply(id: "req-456")

        assert_instance_of(Jsonrpc::ErrorMessage, response)
        assert_equal("req-456", response.id)
      end

      def test_specific_error_classes
        # ParseError
        error = ParseError.new("Parse error")
        assert_equal(Error::PARSE_ERROR, error.code)

        # InvalidRequestError
        error = InvalidRequestError.new("Invalid request")
        assert_equal(Error::INVALID_REQUEST, error.code)

        # MethodNotFoundError
        error = MethodNotFoundError.new("Method not found")
        assert_equal(Error::METHOD_NOT_FOUND, error.code)

        # InvalidParamsError
        error = InvalidParamsError.new("Invalid params")
        assert_equal(Error::INVALID_PARAMS, error.code)

        # InternalError
        error = InternalError.new("Internal error")
        assert_equal(Error::INTERNAL_ERROR, error.code)
      end
    end
  end
end
