# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"

class LogStash::Filters::FixMessage < LogStash::Filters::Base
  # extend self

  # attr_accessor :data_dictionary

  # def configure
  #   yield self
  # end
  config_name "fix_message"

  config :message, validate: :string, default: "Hello World!"

  def register
    # Add instance variables
  end

  def filter(event)

    if @message
      # Replace the event message with our message as configured in the
      # config file.
      event["message"] = @message
    end

    # filter_matched should go in the last line of our successful code
    filter_matched(event)
  end
end
