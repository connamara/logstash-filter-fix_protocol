# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |s|
  s.name          = "logstash-filter-fix_protocol"
  s.version       = "0.1.2"
  s.authors       = ["Connamara Systems"]
  s.email         = ["info@connamara.com"]

  s.summary       = "FIX Protocol Logstash Filter"
  s.description   = "Put your financial application logs to work with logstash FIX filtering"
  s.homepage      = "https://github.com/connamara/logstash-filter-fix_protocol"
  s.licenses      = ['Apache License (2.0)']

  s.files         = Dir['lib/**/*','vendor/**/*','*.gemspec','*.md','CONTRIBUTORS','Gemfile','LICENSE.txt','QUICKFIX_LICENSE.txt','NOTICE.TXT', 'spec/**/*', 'features/**/*']

  s.test_files    = s.files.grep(%r{^(spec|features)/})

  s.require_paths = ["lib"]

  s.metadata = { "logstash_plugin" => "true", "logstash_group" => "filter" }

  s.add_runtime_dependency "logstash-core", ">= 2.0.0.beta2", "< 3.0.0"
  s.add_runtime_dependency "logstash-input-generator"
  s.add_runtime_dependency "activesupport"
  s.add_runtime_dependency "quickfix-jruby"

  s.add_development_dependency "logstash-devutils"
  s.add_development_dependency "bundler", "~> 1.8"
  s.add_development_dependency "rake", "~> 10.0"
  s.add_development_dependency "rspec"
  s.add_development_dependency "pry"
end
