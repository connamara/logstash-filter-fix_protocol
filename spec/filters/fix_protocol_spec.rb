require 'spec_helper'

describe LF::FixProtocol do
  let(:fix_5_config) do
    {
      "fix_message" => "message",
      "session_dictionary_path" => load_fixture("FIXT11.xml"),
      "data_dictionary_path" => load_fixture("FIX50SP1.xml")
    }
  end

  let(:fix_4_config) do
    {
      "fix_message" => "message",
      "data_dictionary_path" => load_fixture("FIX42.xml")
    }
  end

  describe 'config' do
    context 'fix 4 configuration' do
      let(:filter) { LF::FixProtocol.new(fix_4_config) }

      it 'reuses the data dictionary as the session dictionary' do
        expect(filter.data_dictionary).to be_a(LF::DataDictionary)
        expect(filter.session_dictionary == filter.data_dictionary).to be true
      end
    end

    context 'fix 5 configuration' do
      let(:filter) { LF::FixProtocol.new(fix_5_config) }

      it 'instantiates a new data dictionary for a session dictionary' do
        expect(filter.data_dictionary).to be_a(LF::DataDictionary)
        expect(filter.session_dictionary == filter.data_dictionary).to be false
      end
    end
  end

  context 'invalid message' do
    config fix_4_configuration

    invalid_msg = "8=invalid_stuff"

    sample(invalid_msg) do
      insist { subject["_fix_parse_failure"] } == "Missing or garbled message type in #{invalid_msg}"
      insist { subject["message"] } == invalid_msg
    end
  end

  context 'an incoming execution report' do
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

  context 'it removes unparseable key-value pairs' do
    config fix_5_configuration

    execution = "8=FIX.4.2\x019=240\x0135=8\x0134=6\x0149=DUMMY_INC\x0152=20150826-23:10:17.744\x0156=ANOTHER_INC\x0157=Firm_B\x011=Inst_B\x016=0\x0111=151012569\x0117=ITRZ1201508261_24\x0120=0\x0122=8\x0131=1010\x0132=5\x0137=ITRZ1201508261_12\x0138=5\x0139=2\x0140=2\x0141=best_buy\x0144=1011\x0154=1\x0155=ITRZ1\x0160=20150826-23:10:15.547\x01150=2\x01151=0\x0110=227\x01"

    sample(execution) do
      expect { subject }.to output.to_stdout
      filtered_event = subject
      insist { filtered_event["BeginString"] } == "FIX.4.2"
      insist { filtered_event["MsgType"] } == "ExecutionReport"
      insist { filtered_event["SenderCompID"] } == "DUMMY_INC"
      insist { filtered_event["AvgPx"] } == 0.0
      insist { filtered_event["OrdType"] } == "LIMIT"
      insist { filtered_event["LeavesQty"] } == 0.0 # this should fail if parsing gets rescued, but doesnt finish setting on the event object
    end
  end
end
