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

  context 'invalid message - Java::Quickfix::InvalidMessage' do
    config fix_4_configuration

    invalid_msg = "8=invalid_stuff"

    sample(invalid_msg) do
      filtered_event = subject
      insist { filtered_event["tags"] } == ["_fix_parse_failure"]
      insist { filtered_event["message"] } == invalid_msg
    end
  end

  context 'invalid message - ArgumentError' do
    config fix_4_configuration

    invalid_msg = "8=FIX.4.09=8135=D34=349garbled=TW52=<TIME>56=ISLD11=ID21=340=154=155=INTC10=0"

    sample(invalid_msg) do
      filtered_event = subject
      insist { filtered_event["tags"] } == ["_fix_parse_failure"]
      insist { filtered_event["message"] } == invalid_msg
    end
  end

  context 'invalid message - group field not found - Java::Quickfix::FieldNotFound' do
    config fix_4_configuration

    invalid_msg = "8=FIX.4.235=D34=249=TW52=<TIME>56=ISLD11=ID21=140=154=138=200.0055=INTC386=3336=PRE-OPEN336=AFTER-HOURS60=<TIME>"

    sample(invalid_msg) do
      filtered_event = subject
      # adds a tag to warn that fields weren't found in the DD
      insist { filtered_event["tags"] } == ["_fix_field_not_found"]
      insist { filtered_event["unknown_fields"] } == ["386"]
      # correctly parses as much as it can
      insist { filtered_event["OrderQty"]} == 200.0
      insist { filtered_event["OrdType"]} == "MARKET"
      insist { filtered_event["Side"]} == "BUY"
      insist { filtered_event["Symbol"]} == "INTC"
      insist { filtered_event["NoTradingSessions"]} == [{"TradingSessionID"=>"PRE-OPEN"}, {"TradingSessionID"=>"AFTER-HOURS"}, {"386"=>3}] # here's the rescued group field
    end
  end

  context 'invalid message - field name not found' do
    config fix_5_configuration

    execution = "8=FIX.4.2\x019=240\x0135=8\x0134=6\x0149=DUMMY_INC\x0152=20150826-23:10:17.744\x0156=ANOTHER_INC\x0157=Firm_B\x011=Inst_B\x016=0\x0111=151012569\x0117=ITRZ1201508261_24\x0120=0\x0122=8\x0131=1010\x0132=5\x0137=ITRZ1201508261_12\x0138=5\x0139=2\x0140=2\x0141=best_buy\x0144=1011\x0154=1\x0155=ITRZ1\x0160=20150826-23:10:15.547\x01150=2\x01151=0\x0110=227\x01"

    sample(execution) do
      filtered_event = subject
      # adds a tag to warn that fields weren't found in the DD
      insist { filtered_event["tags"] } == ["_fix_field_not_found"]
      insist { filtered_event["unknown_fields"] } == ["20"]
      # correctly parses as much as it can
      insist { filtered_event["BeginString"] } == "FIX.4.2"
      insist { filtered_event["MsgType"] } == "ExecutionReport"
      insist { filtered_event["SenderCompID"] } == "DUMMY_INC"
      insist { filtered_event["AvgPx"] } == 0.0
      insist { filtered_event["OrdType"] } == "LIMIT"
      insist { filtered_event["LeavesQty"] } == 0.0
    end
  end
end
