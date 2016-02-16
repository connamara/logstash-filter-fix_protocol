# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"
require "logstash/filters/data_dictionary"
require "logstash/filters/fix_message"

module LogStash
  module  Filters
    class FixMessageFilter < LogStash::Filters::Base
      class << self
        attr_accessor :data_dictionary_path, :session_dictionary_path

        def configure
          yield self
        end
      end

      attr_reader :data_dictionary, :session_dictionary

      config_name "fix_message"

      config :message, validate: :string, default: "Hello World!"

      def initialize(options = {})
        super(options)

        fail "Need to configure a valid data dictionary path" unless data_dictionary_path

        @data_dictionary = DataDictionary.new(data_dictionary_path)
        # Set session data dictionary variable if using > FIX 5.0
        @session_dictionary = DataDictionary.new(session_dictionary_path || data_dictionary_path)
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

      def data_dictionary_path
        LogStash::Filters::FixMessageFilter::data_dictionary_path
      end

      def session_dictionary_path
        LogStash::Filters::FixMessageFilter::session_dictionary_path
      end
    end
  end
end
