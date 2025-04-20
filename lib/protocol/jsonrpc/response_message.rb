# frozen_string_literal: true

require_relative "message"

module Protocol
  module Jsonrpc
    ResponseMessage = Data.define(:id, :result) do
      include Message

      def initialize(id:, result:)
        super
        unless id.nil? || id.is_a?(String) || id.is_a?(Numeric)
          raise InvalidRequestError.new("ID must be nil, string or number", id)
        end
      end

      def to_h() = super.merge(id:, result:)
      def response?() = true
    end
  end
end
