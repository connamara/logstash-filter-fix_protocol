require 'spec_helper'

binding.pry
describe LogStash::Filters::FixMessage do
  xdescribe '.configure' do
    it 'can set a data dictionary' do
      LogStash::Filters::FixMessage.configure do |config|
        config.data_dictionary = "spec/fixtures"
      end
      expect(LogStash::Filters::FixMessage.data_dictionary).to eq "spec/fixtures"
    end
  end
end
