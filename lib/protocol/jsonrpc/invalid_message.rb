# frozen_string_literal: true

# Released under the MIT License.
# Copyright 2025 by Martin Emde

module Protocol
  module Jsonrpc
    # When the message received is not valid JSON or not a valid JSON-RPC message,
    # this class is returned in place of a normal Message.
    # The error that would have been raised is returned as the error.
    # This simplifies batch processing because invalid messages in the batch
    # can be processed as part of the batch rather than raising and interrupting
    # the batch processing.
    InvalidMessage = Data.define(:error, :id) do
      include Message

      def initialize(error: nil, data: nil, id: nil)
        error = Error.wrap(error, data:, id:)
        super(error:, id: error.id)
      end

      def invalid? = true

      def as_json = raise "InvalidMessage cannot be serialized"

      def reply(...) = ErrorResponse.new(id:, error:)

      def to_json(...) = raise "InvalidMessage cannot be serialized"

      def to_s = raise "InvalidMessage cannot be serialized"
    end
  end
end
