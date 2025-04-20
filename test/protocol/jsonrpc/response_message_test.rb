# frozen_string_literal: true

# Released under the MIT License.
# Copyright 2025 by Martin Emde

require "test_helper"
require "protocol/jsonrpc/response_message"

module Protocol
  module Jsonrpc
    class ResponseTest < Minitest::Test
      def test_initialize_with_required_parameters
        response = ResponseMessage.new(id: "request_id", result: "success")
        assert_equal "request_id", response.id
        assert_equal "success", response.result
      end

      def test_initialize_with_complex_result
        result = {
          status: "success",
          data: {
            id: 123,
            name: "Test Item"
          }
        }
        response = ResponseMessage.new(id: "request_id", result: result)
        assert_equal "request_id", response.id
        assert_equal result, response.result
      end

      def test_initialize_with_array_result
        result = [1, 2, 3, 4, 5]
        response = ResponseMessage.new(id: "request_id", result: result)
        assert_equal "request_id", response.id
        assert_equal result, response.result
      end

      def test_initialize_with_nil_result
        response = ResponseMessage.new(id: "request_id", result: nil)
        assert_equal "request_id", response.id
        assert_nil response.result
      end

      def test_to_h
        response = ResponseMessage.new(id: "request_id", result: {status: "success"})
        expected = {
          jsonrpc: "2.0",
          id: "request_id",
          result: {status: "success"}
        }
        assert_equal expected, response.to_h
        assert_equal expected, response.as_json
      end

      def test_to_h_with_nil_result
        response = ResponseMessage.new(id: "request_id", result: nil)
        expected = {
          jsonrpc: "2.0",
          id: "request_id",
          result: nil
        }
        assert_equal expected, response.to_h
        assert_equal expected, response.as_json
      end

      def test_id_present
        response = ResponseMessage.new(id: "request_id", result: "success")
        assert_equal "request_id", response.id
      end

      def test_as_json
        response = ResponseMessage.new(id: "request_id", result: {status: "success"})
        expected = {
          jsonrpc: "2.0",
          id: "request_id",
          result: {status: "success"}
        }
        assert_equal expected, response.as_json
      end
    end
  end
end
