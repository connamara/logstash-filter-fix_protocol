require 'quickfix'
require 'active_support/core_ext'

module LogStash
  module Filters
    class FixMessage < quickfix.Message
      attr_reader :type, :msg_string, :header, :trailer, :session_dictionary, :data_dictionary, :parsed_string

      def initialize(msg_string, data_dictionary, session_dictionary)
        @session_dictionary = session_dictionary
        @data_dictionary = data_dictionary
        @msg_string = msg_string
        @type = quickfix.MessageUtils.getMessageType(msg_string)

        payload_dict = self.is_admin? ? session_dictionary : data_dictionary

        super(msg_string, data_dictionary, false)

        @header = self.get_header
        @trailer = self.get_trailer
      end

      def is_admin?
        # AKA - use session dictionary || use app dictionary
        quickfix.MessageUtils.isAdminMessage(@type)
      end

      def to_hash
        # TODO: This logic / parsing might make sense in quickfix-j / java world
        # Then, from here, we could inherit from quickfix.Message and call `JSON.parse(self.to_json)`
        header_msg = field_map_to_hash(header, data_dictionary)
        body_msg = field_map_to_hash(self, data_dictionary, type)
        trailer_msg = field_map_to_hash(trailer, data_dictionary)

        header_msg.merge(body_msg).merge(trailer_msg)
      end

      private

      def field_type(tag, data_dictionaries = [])
        data_dictionaries.each do |dd|
          enum  = dd.get_field_type_enum(tag)
          value = enum.get_name unless enum.nil?
          return value if value.present?
        end
      end

      def field_name(tag, data_dictionaries = [])
        data_dictionaries.each do |dd|
          value = dd.get_field_name(tag)
          return value if value.present?
        end
      end

      def field_map_to_hash(field_map, data_dictionary, msg_type = nil, all_dictionaries = [data_dictionary])
        hash = {}
        # field_map iterator is java TreeMap
        # https://github.com/quickfix-j/quickfixj/blob/master/quickfixj-core/src/main/java/quickfix/FieldMap.java#L395
        iter = field_map.iterator

        while iter.has_next
          field = iter.next
          tag = field.get_tag
          value = field.get_value

          if data_dictionary.present?
            if msg_type.present? and data_dictionary.is_group(msg_type, tag)
              group_dd = data_dictionary.get_group(msg_type, tag).get_data_dictionary
              groups = []

              for i in 1..value.to_i
                group_map = field_map.get_group(i, tag)
                groups << field_map_to_hash(group_map, group_dd, msg_type, all_dictionaries << group_dd)
              end

              value = groups
            elsif data_dictionary.is_field(tag)
              f_type = field_type(tag, all_dictionaries)

              value =
                case f_type
                  when "INT", "DAYOFMONTH" then value.to_i
                  when "PRICE", "FLOAT", "QTY" then value.to_f
                  when "BOOLEAN" then value == "Y"
                  when "NUMINGROUP" then field_map.to_hash(value)
                  else
                    value_name = data_dictionary.get_value_name(tag, value)
                    value_name.present? ? value_name : value
                end
            end
            tag = field_name(tag, all_dictionaries)
          end

          hash[tag] = value
        end

        hash
      end
    end
  end
end
