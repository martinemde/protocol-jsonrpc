# frozen_string_literal: true

# Released under the MIT License.
# Copyright 2025 by Martin Emde

require "securerandom"

module Protocol
  module Jsonrpc
    Request = Data.define(:method, :params, :id, :jsonrpc) do
      include Message

      def initialize(method:, params: nil, id: SecureRandom.uuid, jsonrpc: JSONRPC_VERSION)
        unless method.is_a?(String)
          raise InvalidRequestError.new("Method must be a string", data: method.inspect)
        end
        unless params.nil? || params.is_a?(Array) || params.is_a?(Hash)
          raise InvalidRequestError.new("Params must be an array or object", data: params.inspect)
        end
        unless id.is_a?(String) || id.is_a?(Numeric)
          raise InvalidRequestError.new("ID must be a string or number", id:)
        end

        super
      end

      def to_h
        h = super
        h.delete(:params) if params.nil?
        h
      end

      def request? = true

      def reply(*args, &)
        if args.empty? && block_given?
          begin
            result_or_error = yield self
          rescue => error
            return ErrorResponse.new(id:, error:)
          end
        elsif args.length == 1
          result_or_error = args.first
        else
          raise ArgumentError, "wrong number of arguments (given #{args.length}, expected 0 or 1)"
        end

        if result_or_error.is_a?(StandardError)
          ErrorResponse.new(id:, error: result_or_error)
        else
          Response.new(id:, result: result_or_error)
        end
      end
    end
  end
end
