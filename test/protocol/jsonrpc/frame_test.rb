# frozen_string_literal: true

# Released under the MIT License.
# Copyright 2025 by Martin Emde

require "test_helper"
require "protocol/jsonrpc"
require "protocol/jsonrpc/error"
require "protocol/jsonrpc/frame"
require "stringio"

module Protocol
  module Jsonrpc
    class FrameTest < Minitest::Test
      def test_read_from_stream
        raw_json = '{"jsonrpc":"2.0","method":"test"}'
        stream = StringIO.new(raw_json)
        frame = Frame.read(stream)

        assert_instance_of Frame, frame
        assert_equal raw_json, frame.raw_json
      end

      def test_read_from_stream_that_returns_nil
        stream = StringIO.new("")
        frame = Frame.read(stream)

        assert_nil frame
      end

      def test_pack_array_of_messages_or_hashes
        message1 = Notification.new(method: "test1")
        message2 = {"jsonrpc" => "2.0", "method" => "test2"}
        frame = Frame.pack([message1, message2])

        assert_instance_of Frame, frame
        parsed = JSON.parse(frame.raw_json)
        assert_equal 2, parsed.size
        assert_equal "test1", parsed[0]["method"]
        assert_equal "test2", parsed[1]["method"]
      end

      def test_pack_array_with_object_not_responding_to_as_json
        object_without_as_json = Object.new

        assert_raises(ArgumentError) do
          Frame.pack([object_without_as_json])
        end
      end

      def test_pack_hash
        hash = {"jsonrpc" => "2.0", "method" => "test"}
        frame = Frame.pack(hash)

        assert_instance_of Frame, frame
        parsed = JSON.parse(frame.raw_json)
        assert_equal "2.0", parsed["jsonrpc"]
        assert_equal "test", parsed["method"]
      end

      def test_pack_message
        message = Notification.new(method: "test")
        frame = Frame.pack(message)

        assert_instance_of Frame, frame
        parsed = JSON.parse(frame.raw_json)
        assert_equal "2.0", parsed["jsonrpc"]
        assert_equal "test", parsed["method"]
      end

      def test_pack_invalid_object_type
        error = assert_raises(ArgumentError) do
          Frame.pack("invalid string")
        end
        assert_match(/Invalid message type: String/, error.message)
      end

      def test_unpack_valid_json
        raw_json = '{"jsonrpc":"2.0","method":"test","id":"123"}'
        frame = Frame.new(raw_json:)
        data = frame.unpack

        assert_equal({jsonrpc: "2.0", method: "test", id: "123"}, data)
      end

      def test_unpack_invalid_json_raises_error
        frame = Frame.new(raw_json: "{invalid json}")
        assert_raises(JSON::ParserError) do
          frame.unpack
        end
      end

      def test_write_to_stream
        stream = StringIO.new
        frame = Frame.new(raw_json: '{"jsonrpc":"2.0","method":"test"}')
        frame.write(stream)

        stream.rewind
        written_content = stream.read
        assert_equal %({"jsonrpc":"2.0","method":"test"}\n), written_content
      end

      def test_to_json_returns_raw_json
        raw_json = '{"jsonrpc":"2.0","method":"test","id":"123"}'
        frame = Frame.new(raw_json: raw_json)

        assert_equal raw_json, frame.to_json
        assert_equal frame.raw_json, frame.to_json
      end

      def test_to_s_returns_raw_json
        raw_json = '{"jsonrpc":"2.0","method":"test","id":"123"}'
        frame = Frame.new(raw_json: raw_json)

        assert_equal raw_json, frame.to_s
        assert_equal frame.raw_json, frame.to_s
      end
    end
  end
end
