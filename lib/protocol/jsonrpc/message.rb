# frozen_string_literal: true

# Released under the MIT License.
# Copyright 2025 by Martin Emde

require "json"
require "securerandom"
require "timeout"

module Protocol
  module Jsonrpc
    # Protocol::Jsonrpc::Message provides operations for creating and validating JSON-RPC messages.
    # This class handles the pure functional aspects of JSON-RPC like:
    # - Creating properly formatted request/notification messages
    # - Validating incoming messages
    # - Parsing responses and errors
    module Message
      class << self
        # Validate, and return the JSON-RPC message or batch
        # @param data [Hash, Array] The parsed message
        # @return [Message, Array<Message>] The parsed message or batch
        # @raise [ParseError] If the message cannot be parsed
        # @raise [InvalidRequestError] If the message is invalid
        def load(data)
          case data
          when Hash
            from_hash(data)
          when Array
            Batch.load(data)
          else
            InvalidMessage.new(data: data.inspect)
          end
        end

        # @param parsed [Hash] The parsed message
        # @return [Message] The parsed message
        def from_hash(parsed)
          return InvalidMessage.new(data: parsed.inspect) unless parsed.is_a?(Hash)

          jsonrpc = parsed[:jsonrpc]

          case parsed
          in {id:, error:}
            ErrorResponse.new(id:, error: Error.from_message(**error), jsonrpc:)
          in {id:, result:}
            Response.new(id:, result:, jsonrpc:)
          in {id:, method:}
            Request.new(id:, method:, params: parsed[:params], jsonrpc:)
          in {method:}
            Notification.new(method:, params: parsed[:params], jsonrpc:)
          else
            InvalidMessage.new(data: parsed.inspect)
          end
        rescue => error
          InvalidMessage.new(error:, data: parsed.inspect)
        end
      end

      def as_json = to_h

      def to_json(...) = JSON.generate(as_json, ...)

      def to_s = to_json

      # Is this a request? (Request)
      def request? = false

      # Is this a notification? (Notification)
      def notification? = false

      # Is this a response to a request? (Error or Response)
      def response? = false

      # Is this an error response? (ErrorResponse)
      def error? = false

      # Is this an invalid message? (InvalidMessage)
      def invalid? = false
    end
  end
end
