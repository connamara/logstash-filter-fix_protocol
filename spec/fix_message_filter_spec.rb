require 'spec_helper'

describe LogStash::Filters::FixMessage do
  before(:each) do
    LogStash::Filters::FixMessageFilter.configure do |config|
      # should give absolute path to FIX data dictionary
      # TODO: Revisit this once we know how folks will configure this
      config.data_dictionary_path = load_fixture("FIX42.xml")
    end
  end

  describe '.configure' do
    it 'can set a data dictionary path' do
      fix_dict_path = LogStash::Filters::FixMessageFilter.data_dictionary_path
      expect(fix_dict_path).to eq "#{Dir.pwd}/spec/fixtures/FIX42.xml"
      expect(File.exists?(fix_dict_path)).to be true
    end
  end

  describe '#data_dictionary' do
    it 'instantiates a data dictionary from the data dictionary path' do
      fix_filter = LogStash::Filters::FixMessageFilter.new
      expect(fix_filter.data_dictionary).to be_a(LogStash::Filters::DataDictionary)
    end
  end

  context 'an incoming execution report' do
    # TODO: Add Grok Regexp to capture individual FIX messages from logging FIX format
    config <<-CONFIG
      filter {
        fix_message {
          message => ["message"]
        }
      }
    CONFIG

    execution = "8=FIXT.1.1\x0135=8\x0149=ITG\x0156=SILO\x01315=8\x016=100.25\x01410=50.25\x01424=23.45\x01411=Y\x0143=N\x0140=1\x015=N\x01"

    sample(execution) do
      filtered_event = subject
      insist { filtered_event["BeginString"] } == "FIXT.1.1"
      insist { filtered_event["MsgType"] } == "ExecutionReport"
      insist { filtered_event["SenderCompID"] } == "ITG"
      insist { filtered_event["AvgPx"] } == 100.25
      insist { filtered_event["OrdType"] } == "MARKET"
      insist { filtered_event["UnderlyingPutOrCall"] } == 8
    end
  end
end
