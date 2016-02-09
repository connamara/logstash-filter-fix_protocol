require 'spec_helper'

describe FixLogstashPlugin do
  describe '.configure' do
    it 'can set a data dictionary' do
      FixLogstashPlugin.configure do |config|
        config.data_dictionary = "spec/fixtures"
      end
      expect(FixLogstashPlugin.data_dictionary).to eq "spec/fixtures"
    end
  end
end
