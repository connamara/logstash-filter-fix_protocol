require 'spec_helper'

describe LogStash::Filters::FixMessage do
  let(:fix_5_config) do
    {
      "message" => ["message"],
      "session_dictionary_path" => load_fixture("FIXT11.xml"),
      "data_dictionary_path" => load_fixture("FIX50SP1.xml")
    }
  end

  let(:fix_4_config) do
    {
      "message" => ["message"],
      "data_dictionary_path" => load_fixture("FIX42.xml")
    }
  end

  describe 'config' do
    context 'fix 4 configuration' do
      let(:filter) { LogStash::Filters::FixMessageFilter.new(fix_4_config) }

      it 'reuses the data dictionary as the session dictionary' do

        expect(filter.data_dictionary).to be_a(LogStash::Filters::DataDictionary)
        expect(filter.session_dictionary == filter.data_dictionary).to be true
      end
    end

    context 'fix 5 configuration' do
      let(:filter) { LogStash::Filters::FixMessageFilter.new(fix_5_config) }

      it 'instantiates a new data dictionary for a session dictionary' do

        expect(filter.data_dictionary).to be_a(LogStash::Filters::DataDictionary)
        expect(filter.session_dictionary == filter.data_dictionary).to be false
      end
    end
  end

  context 'an incoming execution report' do
    # TODO: Add Grok Regexp to capture individual FIX messages from logging FIX format
    config fix_4_configuration

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
