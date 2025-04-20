# frozen_string_literal: true


require_relative "message"

module Protocol
  module Jsonrpc
    class Connection
      # Initialize a new Connection instance
      # @param framer [Protocol::Jsonrpc::Framer] Any class implementing the Framer interface
      def initialize(framer)
        @framer = framer
      end

      # Write a message to the framer
      # @param message [Protocol::Jsonrpc::Message] The message to write
      # @return [Boolean] True if successful
      def write_message(message)
        @framer.write_message(message)
        true
      end

      # Read a message from the framer
      # @yield [Protocol::Jsonrpc::Message] The read message
      # @return [Protocol::Jsonrpc::Message] The read message
      def read_message(&)
        @framer.read_message(&)
      end

      def close
        @framer.close
      end

      def receive_request(request)
        write(request.reply(result))
      end

      def receive_notification(notification)
        nil
      end

      def receive_response(response)
        response
      end

      def receive_error(error)
        error
      end
    end
  end
end
