# frozen_string_literal: true

require "bundler/gem_tasks"
require "standard/rake"
require "rake/testtask"

Rake::TestTask.new(:test) do |test|
  test.libs << "lib" << "test"
  test.pattern = "test/**/*_test.rb"
end

task default: %i[test standard]
task lint: %i[standard]
