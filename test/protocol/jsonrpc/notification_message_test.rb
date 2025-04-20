# frozen_string_literal: true

require "test_helper"
require "protocol/jsonrpc/notification_message"

module Protocol
  module Jsonrpc
    class NotificationTest < Minitest::Test
      def test_initialize_with_required_parameters
        notification = NotificationMessage.new(method: "test_notification")
        assert_equal "test_notification", notification.method
        assert_nil notification.params
      end

      def test_initialize_with_hash_params
        notification = NotificationMessage.new(
          method: "test_notification",
          params: {event: "updated", data: {id: 123}}
        )
        assert_equal "test_notification", notification.method
        assert_equal({event: "updated", data: {id: 123}}, notification.params)
      end

      def test_initialize_with_array_params
        notification = NotificationMessage.new(
          method: "test_notification",
          params: [1, 2, 3]
        )
        assert_equal "test_notification", notification.method
        assert_equal [1, 2, 3], notification.params
      end

      def test_id_is_always_nil
        notification = NotificationMessage.new(method: "test_notification")
        assert_nil notification.id
      end

      def test_to_h
        notification = NotificationMessage.new(
          method: "test_notification",
          params: {event: "updated"}
        )
        expected = {
          jsonrpc: "2.0",
          method: "test_notification",
          params: {event: "updated"}
        }
        assert_equal expected, notification.to_h
      end

      def test_as_json
        notification = NotificationMessage.new(
          method: "test_notification",
          params: {event: "updated"}
        )
        expected = {
          jsonrpc: "2.0",
          method: "test_notification",
          params: {event: "updated"}
        }
        assert_equal expected, notification.as_json
      end

      def test_empty_params_are_nil_in_hash
        notification = NotificationMessage.new(method: "test_notification", params: [])
        assert_equal [], notification.to_h[:params]

        notification = NotificationMessage.new(method: "test_notification", params: {})
        assert_equal({}, notification.to_h[:params])
      end

      def test_invalid_method
        error = assert_raises(InvalidRequestError) do
          NotificationMessage.new(method: 123)
        end
        assert_match(/Method must be a string/, error.message)
      end

      def test_invalid_params
        error = assert_raises(InvalidRequestError) do
          NotificationMessage.new(method: "test_notification", params: "invalid")
        end
        assert_match(/Params must be an array or object/, error.message)
      end
    end
  end
end
