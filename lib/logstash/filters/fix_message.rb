require 'quickfix'

module LogStash
  module Filters
    class FixMessage < quickfix.Message
      attr_reader :type, :msg_string, :session_dictionary, :data_dictionary, :all_dictionaries, :unknown_fields

      def initialize(msg_string, data_dictionary, session_dictionary)
        @session_dictionary = session_dictionary
        @data_dictionary = data_dictionary
        @msg_string = msg_string
        @type = quickfix.MessageUtils.getMessageType(msg_string)
        @unknown_fields = []
        @all_dictionaries = [@data_dictionary, @session_dictionary]

        super(msg_string, data_dictionary, false)
      end

      def to_hash
        # TODO: This logic / parsing might make sense in quickfix-j / java world
        # Then, from here, we could inherit from quickfix.Message and call `JSON.parse(self.to_json)`
        # OR: Might want to move all this to ruby
        # dd = Hash.from_xml(load_fixture("FIX50SP1.xml")) || https://github.com/jnunemaker/crack
        header_msg  = field_map_to_hash(self.header)
        body_msg    = field_map_to_hash(self, type)
        trailer_msg = field_map_to_hash(self.trailer)

        header_msg.merge(body_msg).merge(trailer_msg)
      end

      private

      def field_type(tag)
        @all_dictionaries.each do |dd|
          enum  = dd.get_field_type(tag)
          value = enum.name unless enum.nil?
          return value if value.present?
        end
      end

      def field_name(tag)
        @all_dictionaries.each do |dd|
          value = dd.get_field_name(tag)
          return value if value.present?
        end

        tag = to_string(tag)
        @unknown_fields << tag
        tag
      end

      def to_string(tag)
        tag.to_s.force_encoding("UTF-8")
      end

      def field_map_to_hash(field_map, msg_type = nil)
        hash = {}
        # java TreeMap: https://github.com/quickfix-j/quickfixj/blob/master/quickfixj-core/src/main/java/quickfix/FieldMap.java#L395
        iter = field_map.iterator

        while iter.has_next
          field = iter.next
          tag   = field.get_tag
          value = field.get_value

          if is_group?(msg_type, tag)
            groups = []

            for i in 1..value.to_i
              begin
                group_map  = field_map.get_group(i, tag)
                group_hash = field_map_to_hash(group_map, msg_type)
              rescue Java::Quickfix::FieldNotFound
                group_hash = { to_string(tag) => i }
                self.unknown_fields << to_string(tag)
              end
              groups << group_hash
            end

            value = groups
          elsif @data_dictionary.is_field(tag)
            value =
              case field_type(tag)
                when "INT", "DAYOFMONTH" then value.to_i
                when "PRICE", "FLOAT", "QTY" then value.to_f
                when "BOOLEAN" then value == "Y"
                else
                  value_name = @data_dictionary.get_value_name(tag, value)
                  value_name.presence || value
              end
          end

          hash[field_name(tag)] = value
        end

        hash
      end

      # A word of caution here: jarred Quickfix/j doesn't recognize tag 802 as a group, so we explicitly ask
      # if the field tag is of type "NUMINGROUP" - see issue #77
      # Tag: 452, value: 4, field_map: LogStash::Filters::FixMessage, @data_dictionary.is_group(8, 452) == true
      # Tag: 802, value: 2, field_map: Java::Quickfix::Group,         @data_dictionary.is_group(8, 802) == false
      def is_group?(msg_type, tag)
        msg_type &&
        @data_dictionary.is_group(msg_type, tag) || field_type(tag) == "NUMINGROUP"
      end
    end
  end
end
