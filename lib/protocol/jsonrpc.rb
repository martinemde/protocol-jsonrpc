# frozen_string_literal: true

# Released under the MIT License.
# Copyright 2025 by Martin Emde

module Protocol
  module Jsonrpc
    JSONRPC_VERSION = "2.0"

    autoload :Batch, "protocol/jsonrpc/batch"
    autoload :Connection, "protocol/jsonrpc/connection"
    autoload :Error, "protocol/jsonrpc/error"
    autoload :ErrorResponse, "protocol/jsonrpc/error_response"
    autoload :Frame, "protocol/jsonrpc/frame"
    autoload :Framer, "protocol/jsonrpc/framer"
    autoload :InvalidMessage, "protocol/jsonrpc/invalid_message"
    autoload :Message, "protocol/jsonrpc/message"
    autoload :Notification, "protocol/jsonrpc/notification"
    autoload :Request, "protocol/jsonrpc/request"
    autoload :Response, "protocol/jsonrpc/response"
    autoload :VERSION, "protocol/jsonrpc/version"
  end
end
