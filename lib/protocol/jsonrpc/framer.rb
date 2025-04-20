# frozen_string_literal: true

# Released under the MIT License.
# Copyright 2025 by Martin Emde

require "protocol/jsonrpc/frame"

module Protocol
  module Jsonrpc
    class Framer
      def initialize(stream, frame_class: Frame)
        @stream = stream
        @frame_class = frame_class
      end

      # Read a frame from the stream
      # @return [Frame] The parsed frame
      def read_frame(&block)
        frame = @frame_class.read(@stream)
        yield frame if block_given?
        frame
      end

      # Write a frame to the stream
      # @param frame [Frame] The frame to write
      def write_frame(frame)
        frame.write(@stream)
      end

      # Flush the stream
      def flush
        @stream.flush
      end

      # Close the stream
      def close
        @stream.close
      end
    end
  end
end
