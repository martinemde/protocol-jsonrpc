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

      # Tests for Error.wrap method
      def test_wrap_with_nil
        error = Error.wrap(nil)
        assert_instance_of(InvalidRequestError, error)
        assert_equal("Invalid Request", error.message)
      end

      def test_wrap_with_nil_and_data
        error = Error.wrap(nil, data: {reason: "missing"}, id: "req-123")
        assert_instance_of(InvalidRequestError, error)
        assert_equal({reason: "missing"}, error.data)
        assert_equal("req-123", error.id)
      end

      def test_wrap_with_string
        error = Error.wrap("Something went wrong")
        assert_instance_of(InternalError, error)
        assert_equal("Something went wrong", error.message)
      end

      def test_wrap_with_string_and_data
        error = Error.wrap("Custom error", data: {details: "info"}, id: "req-456")
        assert_instance_of(InternalError, error)
        assert_equal("Custom error", error.message)
        assert_equal({details: "info"}, error.data)
        assert_equal("req-456", error.id)
      end

      def test_wrap_with_hash
        hash = {code: Error::PARSE_ERROR, message: "Parse failed"}
        error = Error.wrap(hash)
        assert_instance_of(ParseError, error)
        assert_equal("Parse failed", error.message)
      end

      def test_wrap_with_hash_string_keys
        hash = {"code" => Error::INVALID_PARAMS, "message" => "Bad params"}
        error = Error.wrap(hash, id: "req-789")
        assert_instance_of(InvalidParamsError, error)
        assert_equal("Bad params", error.message)
        assert_equal("req-789", error.id)
      end

      def test_wrap_with_existing_error
        original = ParseError.new("Original error", id: "original-id")
        wrapped = Error.wrap(original)
        assert_same(original, wrapped)
      end

      def test_wrap_with_existing_error_updates_data
        original = ParseError.new("Original error")
        wrapped = Error.wrap(original, data: {new: "data"}, id: "new-id")
        assert_same(original, wrapped)
        assert_equal({new: "data"}, wrapped.data)
        assert_equal("new-id", wrapped.id)
      end

      def test_wrap_with_existing_error_preserves_existing_data
        original = ParseError.new("Original error", data: {existing: "data"}, id: "existing-id")
        wrapped = Error.wrap(original, data: {new: "data"}, id: "new-id")
        assert_same(original, wrapped)
        assert_equal({existing: "data"}, wrapped.data)
        assert_equal("existing-id", wrapped.id)
      end

      def test_wrap_with_json_parser_error
        json_error = JSON::ParserError.new("unexpected token")
        error = Error.wrap(json_error)
        assert_instance_of(ParseError, error)
        assert_equal("Parse error: unexpected token", error.message)
      end

      def test_wrap_with_json_parser_error_and_data
        json_error = JSON::ParserError.new("invalid JSON")
        error = Error.wrap(json_error, data: {input: "bad json"}, id: "req-json")
        assert_instance_of(ParseError, error)
        assert_equal("Parse error: invalid JSON", error.message)
        assert_equal({input: "bad json"}, error.data)
        assert_equal("req-json", error.id)
      end

      def test_wrap_with_standard_error
        std_error = StandardError.new("Something broke")
        error = Error.wrap(std_error)
        assert_instance_of(InternalError, error)
        assert_equal("Something broke", error.message)
      end

      def test_wrap_with_standard_error_and_data
        std_error = RuntimeError.new("Runtime failure")
        error = Error.wrap(std_error, data: {stack: "trace"}, id: "req-runtime")
        assert_instance_of(InternalError, error)
        assert_equal("Runtime failure", error.message)
        assert_equal({stack: "trace"}, error.data)
        assert_equal("req-runtime", error.id)
      end

      def test_wrap_with_unknown_type_raises
        unknown_object = Object.new
        assert_raises(Object) do
          Error.wrap(unknown_object)
        end
      end

      # Tests for Error#[] accessor method
      def test_bracket_accessor_code
        error = ParseError.new("Test error")
        assert_equal(Error::PARSE_ERROR, error[:code])
      end

      def test_bracket_accessor_message
        error = ParseError.new("Test message")
        assert_equal("Test message", error[:message])
      end

      def test_bracket_accessor_data
        error = ParseError.new("Test error", data: {key: "value"})
        assert_equal({key: "value"}, error[:data])
      end

      def test_bracket_accessor_data_nil
        error = ParseError.new("Test error")
        assert_nil(error[:data])
      end

      def test_bracket_accessor_invalid_key
        error = ParseError.new("Test error")
        assert_raises(KeyError) do
          error[:invalid]
        end
      end

      # Tests for Error#initialize edge cases
      def test_initialize_with_empty_string_message
        error = ParseError.new("")
        assert_equal("Parse error", error.message) # Should use default message
      end

      def test_initialize_with_nil_message
        error = ParseError.new(nil)
        assert_equal("Parse error", error.message) # Should use default message
      end

      def test_initialize_with_no_message
        error = ParseError.new
        assert_equal("Parse error", error.message) # Should use default message
      end

      # Tests for Error#to_h without data
      def test_to_h_without_data
        error = ParseError.new("Test error")
        expected = {code: Error::PARSE_ERROR, message: "Test error"}
        assert_equal(expected, error.to_h)
      end
    end
  end
end
