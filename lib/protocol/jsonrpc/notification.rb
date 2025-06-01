# frozen_string_literal: true

# Released under the MIT License.
# Copyright 2025 by Martin Emde

module Protocol
  module Jsonrpc
    Notification = Data.define(:method, :params, :jsonrpc) do
      include Message

      def initialize(method:, params: nil, jsonrpc: JSONRPC_VERSION)
        super

        unless method.is_a?(String)
          raise InvalidRequestError.new("Method must be a string", data: method.inspect)
        end
        unless params.nil? || params.is_a?(Array) || params.is_a?(Hash)
          raise InvalidRequestError.new("Params must be an array or object", data: params.inspect)
        end
      end

      def to_h
        h = super
        h.delete(:params) if params.nil?
        h
      end

      # Compatibility with the Message interface, Notifications have no ID
      def id = nil

      # Compatibility with the Request
      # Yields the notificatino for processing but ignores the result
      def reply(*, &)
        yield self if block_given?
        nil # notification always returns nil
      end


      def notification? = true
    end
  end
end
