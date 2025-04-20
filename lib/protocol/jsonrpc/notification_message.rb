# frozen_string_literal: true

# Released under the MIT License.
# Copyright 2025 by Martin Emde

require_relative "message"

module Protocol
  module Jsonrpc
    NotificationMessage = Data.define(:method, :params) do
      include Message

      def initialize(method:, params: nil)
        super

        unless method.is_a?(String)
          raise InvalidRequestError.new("Method must be a string", data: method.inspect)
        end
        unless params.nil? || params.is_a?(Array) || params.is_a?(Hash)
          raise InvalidRequestError.new("Params must be an array or object", data: params.inspect)
        end
      end

      def to_h
        h = super.merge(method:)
        h[:params] = params if params
        h
      end

      def id = nil

      def reply = nil

      def response? = false
    end
  end
end
