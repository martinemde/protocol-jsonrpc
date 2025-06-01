# frozen_string_literal: true

# Released under the MIT License.
# Copyright 2025 by Martin Emde

module Protocol
  module Jsonrpc
    Batch = Data.define(:messages) do
      def self.load(data)
        return InvalidMessage.new(data: data.inspect) if data.empty?

        messages = data.map { |message| Message.load(message) }
        new(messages)
      end

      def to_a = messages
      alias to_ary to_a

      def as_json = to_a.map(&:as_json)
      def to_json(...) = JSON.generate(to_a.map(&:as_json), ...)
      alias to_s to_json

      def reply(&block)
        to_a.filter_map do |message|
          message.reply(&block)
        end
      end

      private

      def method_missing(method, *args, **kwargs, &block)
        if messages.respond_to?(method)
          messages.send(method, *args, **kwargs, &block)
        else
          super
        end
      end

      def respond_to_missing?(method, include_private = false)
        messages.respond_to?(method, include_private) || super
      end
    end
  end
end
