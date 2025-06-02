# frozen_string_literal: true

# Released under the MIT License.
# Copyright 2025 by Martin Emde

module Protocol
  module Jsonrpc
    JSONRPC_VERSION = "2.0"
  end
end

require_relative "jsonrpc/version"
require_relative "jsonrpc/error"
require_relative "jsonrpc/message"
require_relative "jsonrpc/error_response"
require_relative "jsonrpc/invalid_message"
require_relative "jsonrpc/notification"
require_relative "jsonrpc/request"
require_relative "jsonrpc/response"
require_relative "jsonrpc/frame"
require_relative "jsonrpc/framer"
require_relative "jsonrpc/connection"
require_relative "jsonrpc/batch"
