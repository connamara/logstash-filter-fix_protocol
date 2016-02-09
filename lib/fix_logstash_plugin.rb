require "fix_logstash_plugin/version"

module FixLogstashPlugin
  extend self

  attr_accessor :data_dictionary

  def configure
    yield self
  end
end
