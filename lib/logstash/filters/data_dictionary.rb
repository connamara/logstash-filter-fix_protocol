#encoding ascii

require 'rexml/document'
require 'quickfix'

module LogStash
  module  Filters
    class DataDictionary < quickfix.DataDictionary
      attr_reader :file, :reverse_lookup

      def initialize(file_path)
        super(file_path)

        @file = ::File.new(file_path)
        @reverse_lookup = ::Hash.new
        parse_xml
      end

      def get_reverse_value_name(tag, name)
        if @reverse_lookup[tag].has_key?(name)
          @reverse_lookup[tag][name]
        else
          name
        end
      end

      private

      def parse_xml
        doc = ::REXML::Document.new(@file)

        doc.elements.each("fix/fields/field") do |f|
          tag = f.attributes['number'].to_i
          @reverse_lookup[tag] ||= {}

          f.elements.each("value") do |v|
            @reverse_lookup[ tag ][v.attributes['description']] = v.attributes['enum']
          end
        end

        #also map pretty msg type names
        doc.elements.each("fix/messages/message") do |m|
          @reverse_lookup[35][m.attributes['name']] = m.attributes['msgtype']
        end
      end
    end
  end
end
