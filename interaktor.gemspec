Gem::Specification.new do |spec|
  spec.name = "interaktor"
  spec.version = "0.1.3"

  spec.author = "Taylor Thurlow"
  spec.email = "taylorthurlow@me.com"
  spec.description = "A common interface for building service objects."
  spec.summary = "Simple service object implementation"
  spec.homepage = "https://github.com/taylorthurlow/interaktor"
  spec.license = "MIT"
  spec.files = `git ls-files`.split
  spec.test_files = spec.files.grep(/^spec/)
  spec.required_ruby_version = ">= 2.5"
  spec.require_path = "lib"

  spec.add_runtime_dependency "zeitwerk", "~> 2.3.1"

  spec.add_development_dependency "rake", "~> 13.0"
end