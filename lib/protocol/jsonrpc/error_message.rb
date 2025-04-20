# frozen_string_literal: true

require_relative "message"

module Protocol
  module Jsonrpc
    ErrorMessage = Data.define(:id, :error) do
      include Message

      def initialize(id:, error:)
        unless id.nil? || id.is_a?(String) || id.is_a?(Numeric)
          raise InvalidRequestError.new("ID must be nil, string or number", id)
        end

        error = Error.wrap(error)

        super(id:, error:)
      end

      def to_h() = super.merge(id:, error: error.to_h)
      def response?() = true
    end
  end
end
