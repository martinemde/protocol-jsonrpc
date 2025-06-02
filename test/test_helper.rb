# frozen_string_literal: true

# Released under the MIT License.
# Copyright 2025 by Martin Emde

require "simplecov"
SimpleCov.start do
  add_filter "/test/"
  enable_coverage :branch
end

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "json"
require "stringio"
require "socket"

require "minitest/autorun"
require "minitest/pride"

require "protocol/jsonrpc"
