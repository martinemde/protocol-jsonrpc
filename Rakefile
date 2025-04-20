# frozen_string_literal: true

require "bundler/gem_tasks"
require "minitest/test_task"
require "standard/rake"

Minitest::TestTask.create

task default: %i[test standard]

# Load custom tasks
Dir.glob("lib/tasks/**/*.rake").each { |r| load r }
