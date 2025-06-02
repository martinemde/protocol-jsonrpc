# frozen_string_literal: true

# Released under the MIT License.
# Copyright 2025 by Martin Emde

require "test_helper"

module Protocol
  module Jsonrpc
    class FramerTest < Minitest::Test
      def test_read_frame_returns_frame
        stream = StringIO.new(%({"jsonrpc":"2.0","method":"test"}\n))
        framer = Framer.new(stream)

        frame = framer.read_frame
        empty_frame = framer.read_frame

        assert_instance_of Frame, frame
        assert_equal '{"jsonrpc":"2.0","method":"test"}', frame.raw_json.chomp
        assert_nil empty_frame
      end

      def test_read_frame_returns_multiple_frames
        stream = StringIO.new(%({"jsonrpc":"2.0","method":"test"}\n{"jsonrpc":"2.0","method":"test2"}\n))
        framer = Framer.new(stream)

        frame1 = framer.read_frame
        frame2 = framer.read_frame

        assert_instance_of Frame, frame1
        assert_equal '{"jsonrpc":"2.0","method":"test"}', frame1.raw_json.chomp
        assert_instance_of Frame, frame2
        assert_equal '{"jsonrpc":"2.0","method":"test2"}', frame2.raw_json.chomp
      end

      def test_read_frame_returns_nil_when_stream_empty
        stream = StringIO.new("")
        framer = Framer.new(stream)

        frame = framer.read_frame

        assert_nil frame
      end

      def test_read_frame_with_block
        stream = StringIO.new(%({"jsonrpc":"2.0","method":"test"}\n))
        framer = Framer.new(stream)
        yielded_frame = nil

        returned_frame = framer.read_frame do |frame|
          yielded_frame = frame
        end

        assert_instance_of Frame, returned_frame
        assert_equal returned_frame, yielded_frame
        assert_equal '{"jsonrpc":"2.0","method":"test"}', yielded_frame.raw_json.chomp
      end

      def test_read_frame_with_block_when_nil
        stream = StringIO.new("")
        framer = Framer.new(stream)
        yielded_frame = :not_set

        returned_frame = framer.read_frame do |frame|
          yielded_frame = frame
        end

        assert_nil returned_frame
        assert_nil yielded_frame
      end

      def test_write_frame
        stream = StringIO.new
        framer = Framer.new(stream)
        frame = Frame.new(raw_json: '{"jsonrpc":"2.0","method":"test"}')

        framer.write_frame(frame)

        stream.rewind
        written_content = stream.read
        assert_equal %({"jsonrpc":"2.0","method":"test"}\n), written_content
      end

      def test_flush_calls_stream_flush
        stream = StringIO.new
        framer = Framer.new(stream)

        # Mock the flush method to verify it's called
        flush_called = false
        stream.define_singleton_method(:flush) { flush_called = true }

        framer.flush

        assert flush_called
      end

      def test_close_calls_stream_close
        stream = StringIO.new
        framer = Framer.new(stream)

        # Mock the close method to verify it's called
        close_called = false
        stream.define_singleton_method(:close) { close_called = true }

        framer.close

        assert close_called
      end

      def test_read_frame_uses_custom_frame_class
        custom_frame_class = Class.new do
          def self.read(stream)
            "custom_frame_result"
          end
        end

        stream = StringIO.new(%({"test":"data"}\n))
        framer = Framer.new(stream, frame_class: custom_frame_class)

        result = framer.read_frame

        assert_equal "custom_frame_result", result
      end
    end
  end
end
