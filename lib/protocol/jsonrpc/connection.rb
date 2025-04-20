# frozen_string_literal: true

# Released under the MIT License.
# Copyright 2025 by Martin Emde

require_relative "message"

module Protocol
  module Jsonrpc
    class Connection
      # Initialize a new Connection instance
      # @param framer [Protocol::Jsonrpc::Framer] Any class implementing the Framer interface
      def initialize(framer)
        @framer = framer
      end

      def flush
        @framer.flush
      end

      def close
        @framer.close
      end

      # Read a message from the framer
      # @yield [Protocol::Jsonrpc::Message] The read message
      # @return [Protocol::Jsonrpc::Message] The read message
      def read(&block)
        flush
        frame = read_frame
        message = Message.load(frame.unpack)
        yield message if block_given?
        message
      end

      # Write a message to the framer
      # @param message [Protocol::Jsonrpc::Message, Array<Protocol::Jsonrpc::Message>] The message(s) to write
      # @return [Boolean] True if successful
      def write(message)
        frame = Frame.pack(message)
        write_frame(frame)
        true
      end

      # Low level read a frame from the framer
      # @yield [Protocol::Jsonrpc::Frame] The read frame
      # @return [Protocol::Jsonrpc::Frame] The read frame
      def read_frame(&)
        frame = @framer.read_frame
        yield frame if block_given?
        frame
      end

      # Low level write a frame to the framer
      # @param frame [Protocol::Jsonrpc::Frame] The frame to write
      # @return [Boolean] True if successful
      def write_frame(frame)
        @framer.write_frame(frame)
      end
    end
  end
end
