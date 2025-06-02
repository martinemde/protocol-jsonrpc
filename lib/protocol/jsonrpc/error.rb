# frozen_string_literal: true

# Released under the MIT License.
# Copyright 2025 by Martin Emde

require "securerandom"
require "json"

module Protocol
  module Jsonrpc
    class Error < StandardError
      PARSE_ERROR = -32_700
      INVALID_REQUEST = -32_600
      METHOD_NOT_FOUND = -32_601
      INVALID_PARAMS = -32_602
      INTERNAL_ERROR = -32_603

      ERROR_MESSAGES = Hash.new("Error").merge(
        PARSE_ERROR => "Parse error",
        INVALID_REQUEST => "Invalid Request",
        METHOD_NOT_FOUND => "Method not found",
        INVALID_PARAMS => "Invalid params",
        INTERNAL_ERROR => "Internal error"
      ).freeze

      # Factory method to create the appropriate error type
      # @param code [Integer] The JSON-RPC error code
      # @param message [String] The error message
      # @param data [#as_json, #to_json] Serializable data to return to the client
      # @param id [String, Integer] The request ID
      # @return [Error] The appropriate error instance
      def self.from_message(code:, message:, data: nil, id: nil)
        case code
        when PARSE_ERROR
          ParseError.new(message, data:, id:)
        when INVALID_REQUEST
          InvalidRequestError.new(message, data:, id:)
        when METHOD_NOT_FOUND
          MethodNotFoundError.new(message, data:, id:)
        when INVALID_PARAMS
          InvalidParamsError.new(message, data:, id:)
        when INTERNAL_ERROR
          InternalError.new(message, data:, id:)
        else
          new(message, data:, id:)
        end
      end

      def self.wrap(error, data: nil, id: nil)
        case error
        in nil
          InvalidRequestError.new(data:, id:)
        in String
          InternalError.new(error, data:, id:)
        in Hash
          error = error.transform_keys(&:to_sym)
          from_message(id: id, data: data, **error)
        in Jsonrpc::Error
          error.data ||= data if data
          error.id ||= id if id
          error
        in JSON::ParserError
          ParseError.new("Parse error: #{error.message}", data:, id:)
        in StandardError
          InternalError.new(error.message, data:, id:)
        else
          raise error
        end
      end

      attr_accessor :data, :id
      attr_reader :code

      def initialize(message = nil, data: nil, id: nil)
        message = nil if message&.empty?
        message ||= ERROR_MESSAGES[code]
        super(message)
        @data = data
        @id = id
      end

      def reply(id: @id)
        ErrorResponse.new(id:, error: self)
      end

      def to_h
        h = {code:, message:}
        h[:data] = data if data
        h
      end

      def [](key)
        case key
        when :code
          code
        when :message
          message
        when :data
          data
        else
          raise KeyError, "Invalid key: #{key}"
        end
      end
    end

    # Error raised when a JSON-RPC parse error is received from the server
    # Raised when error code is -32700
    class ParseError < Error
      def code
        PARSE_ERROR
      end
    end

    # Error raised when a JSON-RPC invalid request error is received from the server
    # Raised when error code is -32600
    class InvalidRequestError < Error
      def code
        INVALID_REQUEST
      end
    end

    # Error raised when a JSON-RPC method not found error is received from the server
    # Raised when error code is -32601
    class MethodNotFoundError < Error
      def code
        METHOD_NOT_FOUND
      end
    end

    # Error raised when a JSON-RPC invalid params error is received from the server
    # Raised when error code is -32602
    class InvalidParamsError < Error
      def code
        INVALID_PARAMS
      end
    end

    # Error raised when a JSON-RPC internal error is received from the server
    # Raised when error code is -32603
    class InternalError < Error
      def code
        INTERNAL_ERROR
      end
    end
  end
end
