# frozen_string_literal: true

# Released under the MIT License.
# Copyright 2025 by Martin Emde

module Protocol
  module Jsonrpc
    ErrorResponse = Data.define(:id, :error, :jsonrpc) do
      include Message

      def initialize(id:, error:, jsonrpc: JSONRPC_VERSION)
        unless id.nil? || id.is_a?(String) || id.is_a?(Numeric)
          raise InvalidRequestError.new("ID must be nil, string or number", id: id)
        end

        error = Error.wrap(error)

        super
      end

      def to_h = super.merge(error: error.to_h)

      def error? = true

      def response? = true
    end
  end
end
