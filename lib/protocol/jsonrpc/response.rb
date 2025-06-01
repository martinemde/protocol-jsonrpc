# frozen_string_literal: true

# Released under the MIT License.
# Copyright 2025 by Martin Emde

module Protocol
  module Jsonrpc
    Response = Data.define(:id, :result, :jsonrpc) do
      include Message

      def initialize(id:, result:, jsonrpc: JSONRPC_VERSION)
        unless id.nil? || id.is_a?(String) || id.is_a?(Numeric)
          raise InvalidRequestError.new("ID must be nil, string, or number", id:)
        end

        super
      end

      def response? = true
    end
  end
end
