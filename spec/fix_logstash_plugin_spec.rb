require 'spec_helper'

describe LogStash::Filters::FixMessage do
  before(:each) do
    LogStash::Filters::FixMessage.configure do |config|
      # should give absolute path to FIX data dictionary
      # TODO: Revisit this once we know how folks will configure this
      config.data_dictionary_path = load_fixture("FIX42.xml")
    end
  end

  describe '.configure' do
    it 'can set a data dictionary path' do
      fix_dict_path = LogStash::Filters::FixMessage.data_dictionary_path
      expect(fix_dict_path).to eq "#{Dir.pwd}/spec/fixtures/FIX42.xml"
      expect(File.exists?(fix_dict_path)).to be true
    end
  end

  describe '#data_dictionary' do
    it 'instantiates a data dictionary from the data dictionary path' do
      fix_filter = LogStash::Filters::FixMessage.new
      expect(fix_filter.data_dictionary).to be_a(LogStash::Filters::DataDictionary)
    end
  end
end
