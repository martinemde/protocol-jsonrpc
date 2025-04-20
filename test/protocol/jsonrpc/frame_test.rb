# frozen_string_literal: true

# Released under the MIT License.
# Copyright 2025 by Martin Emde

require "test_helper"
require "protocol/jsonrpc"
require "protocol/jsonrpc/error"
require "protocol/jsonrpc/frame"

module Protocol
  module Jsonrpc
    class FrameTest < Minitest::Test
      def test_parse_valid_request
        json = '{"jsonrpc":"2.0","id":"123","method":"test_method","params":{"foo":"bar"}}'
        data = Frame.new(json:).unpack

        assert_equal "123", data[:id]
        assert_equal "test_method", data[:method]
        assert_equal({ foo: "bar" }, data[:params])
      end

      def test_parse_valid_notification
        json = '{"jsonrpc":"2.0","method":"test_notification"}'
        data = Frame.new(json:).unpack

        assert_equal "test_notification", data[:method]
        assert_nil data[:params]
        assert_nil data[:id]
      end

      def test_parse_valid_response
        json = '{"jsonrpc":"2.0","id":"123","result":{"status":"success"}}'
        data = Frame.new(json:).unpack

        assert_equal "123", data[:id]
        assert_equal({ status: "success" }, data[:result])
      end

      def test_parse_valid_error_response
        json = '{"jsonrpc":"2.0","id":"123","error":{"code":-32600,"message":"Invalid Request"}}'
        data = Frame.new(json:).unpack

        assert_equal "123", data[:id]
        assert_equal({ code: -32600, message: "Invalid Request" }, data[:error].to_h)
      end

      def test_parse_valid_error_response_with_nil_id
        json = '{"jsonrpc":"2.0","id":null,"error":{"code":-32600,"message":"Invalid Request"}}'
        data = Frame.new(json:).unpack

        assert_nil data[:id]
        assert_equal({ code: -32600, message: "Invalid Request" }, data[:error].to_h)
      end

      def test_parse_valid_batch_request
        json = '[' \
          '{"jsonrpc":"2.0","id":"123","method":"test_method","params":{"foo":"bar"}},' \
          '{"jsonrpc":"2.0","id":"456","method":"test_method","params":{"foo":"bar"}}' \
        ']'
        data = Frame.new(json:).unpack

        assert_equal 2, data.size
        assert_equal "123", data[0][:id]
        assert_equal "test_method", data[0][:method]
        assert_equal({ foo: "bar" }, data[0][:params])
        assert_equal "456", data[1][:id]
        assert_equal "test_method", data[1][:method]
        assert_equal({ foo: "bar" }, data[1][:params])
      end

      def test_parse_valid_batch_response
        json = '[' \
          '{"jsonrpc":"2.0","id":"123","result":{"status":"success"}},' \
          '{"jsonrpc":"2.0","id":"456","result":{"status":"success"}}' \
        ']'
        data = Frame.new(json:).unpack

        assert_equal 2, data.size
        assert_equal "123", data[0][:id]
        assert_equal({ status: "success" }, data[0][:result])
        assert_equal "456", data[1][:id]
        assert_equal({ status: "success" }, data[1][:result])
      end

      def test_parse_valid_batch_mixed_response_and_error_response
        json = '[' \
          '{"jsonrpc":"2.0","id":"123","result":{"status":"success"}},' \
          '{"jsonrpc":"2.0","id":null,"error":{"code":-32600,"message":"Invalid request"}}' \
        ']'
        data = Frame.new(json:).unpack

        assert_equal 2, data.size
        assert_equal "123", data[0][:id]
        assert_equal({ status: "success" }, data[0][:result])
        assert_nil data[1][:id]
        assert_equal({ code: -32600, message: "Invalid request" }, data[1][:error].to_h)
      end

      def test_invalid_json
        json = '{invalid json}'
        error = assert_raises(ParseError) do
          Frame.new(json:).unpack
        end
        assert_match(/Failed to parse message/, error.message)
      end
    end
  end
end
