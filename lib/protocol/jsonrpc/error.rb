# frozen_string_literal: true

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

      MESSAGES = Hash.new("Error").merge(
        PARSE_ERROR => "Parse error",
        INVALID_REQUEST => "Invalid Request",
        METHOD_NOT_FOUND => "Method not found",
        INVALID_PARAMS => "Invalid params",
        INTERNAL_ERROR => "Internal error"
      ).freeze

      # Factory method to create the appropriate error type
      # @param id [String, Integer] The request ID
      # @param error [Hash] The error data from the JSON-RPC response
      # @return [Error] The appropriate error instance
      def self.from_message(code:, message:, data: nil)
        case code
        when PARSE_ERROR
          ParseError.new(message, data)
        when INVALID_REQUEST
          InvalidRequestError.new(message, data)
        when METHOD_NOT_FOUND
          MethodNotFoundError.new(message, data)
        when INVALID_PARAMS
          InvalidParamsError.new(message, data)
        when INTERNAL_ERROR
          InternalError.new(message, data)
        else
          new(message, data)
        end
      end

      def self.wrap(error)
        case error
        in Hash
          error = error.transform_keys(&:to_sym)
          from_message(**error)
        in Jsonrpc::Error
          error
        in JSON::ParserError
          ParseError.new(error.message, error)
        in StandardError
          InternalError.new(error.message, error)
        else
          raise error
        end
      end

      attr_reader :data, :code

      def initialize(message = nil, data = nil)
        message = nil if message&.empty?
        super([MESSAGES[code], message].compact.uniq.join(": "))
        @data = data
      end

      def to_response(id: nil)
        ErrorMessage.new(id:, error: self)
      end

      def to_h
        h = { code:, message: }
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
