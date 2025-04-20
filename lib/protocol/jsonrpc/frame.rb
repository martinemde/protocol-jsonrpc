# frozen_string_literal: true

require "json"
require_relative "error"

module Protocol
  module Jsonrpc
    # Frame represents the raw JSON data structure of a JSON-RPC message
    # before it's validated and converted into a proper Message object.
    # This handles the parsing of JSON and initial structure validation.
    Frame = Data.define(:json) do
      # Read a frame from the stream
      # @param stream [IO] The stream to read from
      # @return [Frame, nil] The parsed frame or nil if the stream is empty
      def self.read(stream)
        json = stream.gets
        return nil if json.nil?
        new(json:)
      end

      # Unpack the json into a JSON object
      # @return [Hash] The parsed JSON object
      def unpack
        JSON.parse(json, symbolize_names: true)
      rescue JSON::ParserError => e
        raise ParseError.new("Failed to parse message: #{e.message}", data: json)
      end

      def self.pack(message)
        case message
        when Array
          new(json: message.map { |msg| msg.is_a?(Message) ? msg.as_json : msg }.to_json)
        when Hash, Message
          new(json: message.to_json)
        else
          raise ArgumentError, "Invalid message type: #{message.class}"
        end
      end

      def write(stream)
        stream.write("#{json}\n")
      end
    end
  end
end
