# frozen_string_literal: true

# Released under the MIT License.
# Copyright 2025 by Martin Emde

require "securerandom"
require_relative "message"

module Protocol
  module Jsonrpc
    RequestMessage = Data.define(:method, :params, :id) do
      include Message

      def initialize(method:, params: nil, id: SecureRandom.uuid)
        unless method.is_a?(String)
          raise InvalidRequestError.new("Method must be a string", data: method.inspect)
        end
        unless params.nil? || params.is_a?(Array) || params.is_a?(Hash)
          raise InvalidRequestError.new("Params must be an array or object", data: params.inspect)
        end
        unless id.is_a?(String) || id.is_a?(Numeric)
          raise InvalidRequestError.new("ID must be a string or number", id:)
        end

        super(method:, params:, id:)
      end

      def to_h()
        h = super.merge(id:, method:)
        h[:params] = params if params
        h
      end

      def response?() = false
    end
  end
end
