# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |s|
  s.name          = "logstash-filter-fix_message"
  s.version       = "0.1.0"
  s.authors       = ["Connamara Systems"]
  s.email         = ["dhall@connamara.com"]

  s.summary       = "FIX protocol logstash filter"
  s.description   = "Put your financial application logs work for you with logstash FIX filtering"
  s.homepage      = "TODO: [gem's public repo URL]"
  s.license       = "MIT"

  s.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(spec|features)/}) }
  s.bindir        = "exe"
  s.executables   = s.files.grep(%r{^exe/}) { |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.metadata = { "logstash_plugin" => "true", "logstash_group" => "filter" }

  s.add_runtime_dependency "logstash-core", ">= 2.0.0.beta2", "< 3.0.0"
  s.add_runtime_dependency "logstash-input-generator"
  s.add_runtime_dependency "activesupport"
  s.add_runtime_dependency "quickfix-jruby"

  s.add_development_dependency "logstash-devutils"
  s.add_development_dependency "cucumber"
  s.add_development_dependency "bundler", "~> 1.8"
  s.add_development_dependency "rake", "~> 10.0"
  s.add_development_dependency "rspec"
  s.add_development_dependency "pry"
  s.add_development_dependency "service_manager"
end
