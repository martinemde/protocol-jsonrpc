# frozen_string_literal: true

# Released under the MIT License.
# Copyright 2025 by Martin Emde

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

      # Read the next message or batch of messages from the framer
      # @yield [Protocol::Jsonrpc::Message] Each message is yielded to the block
      # @return [Protocol::Jsonrpc::Message, Protocol::Jsonrpc::Batch] The message or batch of messages
      def read(&block)
        flush
        frame = read_frame
        Message.load(frame.unpack)
      rescue => e
        InvalidMessage.new(error: e)
      end

      # Write a message to the framer
      # @param message [Protocol::Jsonrpc::Message, Array<Protocol::Jsonrpc::Message>, Batch] The message(s) to write
      # @return [Boolean] True if successful
      def write(message)
        write_frame Frame.pack(message)
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
