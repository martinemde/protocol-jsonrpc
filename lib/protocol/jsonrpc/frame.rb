# frozen_string_literal: true

# Released under the MIT License.
# Copyright 2025 by Martin Emde

require "json"

module Protocol
  module Jsonrpc
    # Frame represents the raw JSON data structure of a JSON-RPC message
    # before it's validated and converted into a proper Message object.
    # Handles translation between JSON strings and Ruby Hashes and
    # reading and writing to a stream.
    Frame = Data.define(:raw_json) do
      class << self
        # Read a frame from the stream
        # @param stream [IO] An objects that responds to `gets` and returns a String
        # @return [Frame, nil] The parsed frame or nil if the stream is empty
        def read(stream)
          raw_json = stream.gets
          return nil if raw_json.nil?
          new(raw_json: raw_json.strip)
        end

        # Pack a message into a frame
        # @param message [Message, Array<Message>] The message to pack
        # @return [Frame] an instance that can be written to a stream
        # @raise [ArgumentError] if the message is not a Message or Array of Messages
        def pack(message)
          if message.is_a?(Array)
            new(raw_json: message.map { |msg| as_json(msg) }.to_json)
          else
            new(raw_json: as_json(message).to_json)
          end
        end

        private def as_json(message)
          return message if message.is_a?(Hash)
          return message.as_json if message.respond_to?(:as_json)
          raise ArgumentError, "Invalid message type: #{message.class}. Must be a Hash or respond to :as_json."
        end
      end

      # Unpack the raw_json into a Hash representing the JSON object
      # Symbolizes the keys of the Hash.
      # @return [Hash] The parsed JSON object
      # @raise [ParseError] if the JSON is invalid
      def unpack
        JSON.parse(raw_json, symbolize_names: true)
      end

      def to_json(...) = raw_json

      def to_s = raw_json

      # Write the frame to a stream
      # @param stream [IO] The stream to write to
      # @return [void]
      def write(stream)
        stream.write("#{raw_json}\n")
      end
    end
  end
end
