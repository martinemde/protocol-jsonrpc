# frozen_string_literal: true

require "protocol/jsonrpc/message"

module Protocol
  module Jsonrpc
    class Framer
      def initialize(stream)
        @stream = stream
      end

      # Read a message from the stream
      def read_message(&)
        @stream.flush
        message = Message.read(@stream)
        yield message if block_given?
        message
      end

      # Write a message to the stream
      def write_message(message)
        @stream.write(message.to_json + "\n")
      end

      # Flush the stream
      def flush
        @stream.flush
      end

      def close
        @stream.close
      end
    end
  end
end
