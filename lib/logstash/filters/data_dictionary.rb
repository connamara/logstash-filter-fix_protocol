require 'quickfix'

module LogStash
  module  Filters
    class DataDictionary < quickfix.DataDictionary
      attr_reader :file

      def initialize(file_path)
        @file = ::File.new(file_path) # throw an exception if the file isn't found

        super(file_path)
      end

    end
  end
end
