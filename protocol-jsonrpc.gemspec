# frozen_string_literal: true

require_relative "lib/protocol/jsonrpc/version"

Gem::Specification.new do |spec|
  spec.name = "protocol-jsonrpc"
  spec.version = Protocol::Jsonrpc::VERSION
  spec.authors = ["Martin Emde"]
  spec.email = ["me@martinemde.com"]

  spec.summary = "JSON-RPC 2.0 protocol implementation"
  spec.description = "JSON-RPC 2.0 protocol implementation"
  spec.homepage = "https://github.com/martinemde/protocol-jsonrpc"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/martinemde/protocol-jsonrpc"
  spec.metadata["changelog_uri"] = "https://github.com/martinemde/protocol-jsonrpc/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile .rspec .standard.yml .rubocop.yml Rakefile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "json", "~> 2.10"
end
