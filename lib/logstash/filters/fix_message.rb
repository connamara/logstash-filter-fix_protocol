# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"
require "logstash/filters/data_dictionary"

module LogStash
  module  Filters
    class FixMessage < LogStash::Filters::Base
      class << self
        attr_accessor :data_dictionary_path

        def configure
          yield self
        end
      end

      attr_reader :data_dictionary

      config_name "fix_message"

      config :message, validate: :string, default: "Hello World!"

      def initialize(options = {})
        super(options)

        fail "Need to configure a valid data dictionary path" unless self.class.data_dictionary_path
        @data_dictionary = DataDictionary.new(self.class.data_dictionary_path)
      end

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
  end
end
