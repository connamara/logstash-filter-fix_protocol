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

      # TODO: I really don't understand what's this doing in relation to event var passed to filter
      config :message, validate: :array, default: []

      # TODO: Swap out configure block with these vars
      # config :data_dictionary, validate: :string, default: "ABSOLUTE/PATH/TO/YOUR/DD"
      # config :session_dictionary, validate: :string, default: "ABSOLUTE/PATH/TO/YOUR/FIX.50/SESS/DD"

      def initialize(options = {})
        super(options)

        fail "Need to configure a valid data dictionary path" unless data_dictionary_path

        @data_dictionary = DataDictionary.new(data_dictionary_path)
        # Set session data dictionary variable if using > FIX 5.0
        @session_dictionary = DataDictionary.new(session_dictionary_path || data_dictionary_path)
      end

      def register
        # Add instance variables
        # I DON'T REALLY NEED THIS, CUZ I'M CALLING SUPER IN INITIALIZE
      end

      def filter(event)
        if @message
          # Replace the event message with our message as configured in the
          # config file.
          fix_message = FixMessage.new(event["message"], data_dictionary, session_dictionary)

          # TODO: Iterate through JSON key / value pairs and
          # set event[key] = value
          # (i.e. event['SIDE'] = "BUY")
          fix_message.to_hash.each do |key, value|
            case
            when value.is_a?(Hash)
              # TODO: Iterate
            when value.is_a?(Array)
              # TODO: Again
            else
              event[key] = value
            end
          end

        end

        # filter_matched should go in the last line of our successful code
        # TODO: What the hell is this doing?
        filter_matched(event)
      end

      def assign_vars(object)
        # TODO: potential recursive function
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
