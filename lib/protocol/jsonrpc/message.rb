# frozen_string_literal: true

require "json"
require "securerandom"
require "timeout"
require_relative "error"

module Protocol
  module Jsonrpc
    # JsonrpcMessage provides stateless operations for creating and validating JSON-RPC messages.
    # This class handles the pure functional aspects of JSON-RPC like:
    # - Creating properly formatted request/notification messages
    # - Validating incoming messages
    # - Parsing responses and errors
    module Message
      JSONRPC_VERSION = "2.0"

      class << self
        # Read a message from a stream
        # @param stream [IO::Stream] The stream to read from
        # @param timeout [Integer, Float, nil] The timeout in seconds
        # @return [Message] The parsed message
        def read(stream, timeout: nil)
          message = stream.gets
          parse(message)
        end

        # Deserialize, validate, and return the JSON-RPC message(s) array
        # @param message [String] The JSON-RPC message to parse
        # @return [Array<Message>] An array of messages
        # @raise [ParseError] If the message cannot be parsed
        # @raise [InvalidRequestError] If the message is invalid
        def parse(message)
          parsed = JSON.parse(message, symbolize_names: true)

          case parsed
          when Hash
            from_hash(parsed)
          when Array
            from_array(parsed)
          else
            raise InvalidRequestError.new("Invalid request object", parsed)
          end
        rescue JSON::ParserError => e
          raise ParseError.new("Failed to parse message: #{e.message}", message)
        end

        # This is wrong, it seems like we need to parse each message
        # in the array fully, collecting the entire result and then
        # returning the array of results.
        # The problem is that the errors should get raised and then
        # handled by our responder which turns them into ErrorMessages
        # and then the errors get returned to the client.
        def from_array(array)
          raise InvalidRequestError.new("Empty batch", array) if array.empty?

          array.map do |msg|
            begin
              from_hash(msg)
            rescue => e
              Error.wrap(e)
            end
          end
        end

        # @param parsed [Hash] The parsed message
        # @return [Message] The parsed message
        def from_hash(parsed)
          raise InvalidRequestError.new("Expected hash, got #{parsed.class}", parsed) unless parsed.is_a?(Hash)
          raise InvalidRequestError.new("Unexpected JSON-RPC version", parsed) unless parsed[:jsonrpc] == JSONRPC_VERSION

          case parsed
          in { id:, error: }
            ErrorMessage.new(id:, error: Error.from_message(**error))
          in { id:, result: }
            ResponseMessage.new(id:, result:)
          in { id:, method: }
            RequestMessage.new(id:, method:, params: parsed[:params])
          in { method: }
            NotificationMessage.new(method:, params: parsed[:params])
          else
            raise ParseError.new("Unknown message: #{parsed.inspect}", parsed)
          end
        end
      end

      def to_h() = { jsonrpc: JSONRPC_VERSION }
      def to_hash() = to_h
      def as_json() = to_h
      def to_json(...) = JSON.generate(as_json, ...)
      def to_s() = to_json
      def response?() = false
      def match?(message) = false

      def reply(result_or_error)
        if result_or_error.is_a?(StandardError)
          ErrorMessage.new(id:, error: result_or_error)
        else
          reply(result_or_error)
        end
      end
    end
  end
end
