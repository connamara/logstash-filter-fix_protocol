require 'spec_helper'

describe LF::FixMessage do
  let(:message_str) { "8=FIXT.1.1\x0135=8\x0149=ITG\x0156=SILO\x01315=8\x016=100.25\x01410=50.25\x01424=23.45\x01411=Y\x0143=N\x0140=1\x015=N\x01" }
  let(:another_str) { "8=FIXT.1.1\x0135=B\x0149=ITG\x0156=SILO\x01148=Market Bulls Have Short Sellers on the Run\x0133=2\x0158=The bears have been cowed by the bulls.\x0158=Buy buy buy\x01354=0\x0143=N\x0140=1\x015=N\x01" }

  let(:data_dictionary) { LF::DataDictionary.new(load_fixture("FIX50SP1.xml")) }
  let(:session_dictionary) { LF::DataDictionary.new(load_fixture("FIXT11.xml")) }
  let(:message) { LF::FixMessage.new(message_str, data_dictionary, session_dictionary) }
  let(:message2) { LF::FixMessage.new(another_str, data_dictionary, session_dictionary) }

  let(:fix_4)  { {data_dictionary: "FIX42.xml", session_dictionary: nil} }
  let(:fix_5)  { {data_dictionary: "FIX50SP1.xml", session_dictionary: "FIXT11.xml"} }

  describe '#to_hash' do
    it 'converts the FIX message string to a hash in human readable format' do
      expect(message.to_hash).to eq({
        "BeginString"=>"FIXT.1.1",
        "MsgType"=>"ExecutionReport",
        "PossDupFlag"=>false,
        "SenderCompID"=>"ITG",
        "TargetCompID"=>"SILO",
        "AdvTransType"=>"NEW",
        "AvgPx"=>100.25,
        "OrdType"=>"MARKET",
        "UnderlyingPutOrCall"=>8,
        "WtAverageLiquidity"=>"50.25",
        "ExchangeForPhysical"=>true,
        "DayOrderQty"=>23.45
      })

      expect(message2.to_hash).to eq({
        "BeginString"=>"FIXT.1.1",
        "MsgType"=>"News",
        "PossDupFlag"=>false,
        "SenderCompID"=>"ITG",
        "TargetCompID"=>"SILO",
        "AdvTransType"=>"NEW",
        "NoLinesOfText"=>[
           {
             "Text"=>"The bears have been cowed by the bulls."
           }, {
             "Text"=>"Buy buy buy", "EncodedTextLen"=>"0"
           }
         ],
        "OrdType"=>"MARKET",
        "Headline"=>"Market Bulls Have Short Sellers on the Run"
      })
    end
  end

  def should_parse_fix_messages(file_path, dictionary = "FIX42.xml", session_dictionary = nil)
    data_dictionary = LF::DataDictionary.new(load_fixture(dictionary))
    session_dictionary = session_dictionary.present? ? LF::DataDictionary.new(load_fixture(session_dictionary)) : data_dictionary

    File.open(load_fixture(file_path), encoding: 'UTF-8') do |file|
      file.each_entry do |line|
        line.chomp! # remove new line character
        message = LF::FixMessage.new(line, data_dictionary, session_dictionary)
        yield(message.to_hash)
      end
    end
  end

  describe '#field_map_to_hash' do
    context 'invalid message - field name not found' do
      let(:fix_string) { "8=FIX.4.29=24035=834=649=DUMMY_INC52=20150826-23:10:17.74456=ANOTHER_INC57=Firm_B1=Inst_B6=011=best_buy14=517=ITRZ1201508261_2420=022=831=101032=537=ITRZ1201508261_1238=539=27012=22740=241=best_buy44=101154=155=ITRZ160=20150826-23:10:15.547150=2151=010=227" }

      it 'adds an error object and uses the data dictionary index number as the key' do
        data_dictionary = LF::DataDictionary.new(load_fixture(fix_5[:data_dictionary]))
        sess_dictionary = LF::DataDictionary.new(load_fixture(fix_5[:session_dictionary]))

        fix_message = LF::FixMessage.new(fix_string, data_dictionary, sess_dictionary)
        hash = fix_message.to_hash
        # Side Note: field 20, LastShares, was changed between FIX 4 / 5
        expect(hash["20"]).to eq("0")
        expect(hash["7012"]).to eq("227")
        expect(fix_message.unknown_fields.include?("20")).to be true
        expect(fix_message.unknown_fields.include?("7012")).to be true
      end
    end

    context 'invalid message - group field name not found (Java::Quickfix::FieldNotFound)' do
      let(:fix_string) { "8=FIX.4.235=D34=249=TW52=<TIME>56=ISLD11=ID21=140=154=138=200.0055=INTC386=3336=PRE-OPEN336=AFTER-HOURS60=<TIME>" }

      it 'adds an error object and uses the data dictionary index number as the key' do
        data_dictionary = LF::DataDictionary.new(load_fixture(fix_5[:data_dictionary]))
        sess_dictionary = LF::DataDictionary.new(load_fixture(fix_5[:session_dictionary]))

        fix_message = LF::FixMessage.new(fix_string, data_dictionary, sess_dictionary)
        hash = fix_message.to_hash
        expect(fix_message.unknown_fields.include?("386")).to be true
        expect(hash["NoTradingSessions"]).to eq([{"TradingSessionID"=>"PRE-OPEN"}, {"TradingSessionID"=>"AFTER-HOURS"}, {"386"=>3}])
      end
    end
  end

  context 'message types' do
    # most data is from: http://fixparser.targetcompid.com/
    context 'heartbeats' do
      it 'can parse these' do
        [fix_4, fix_5].each do |version|
          should_parse_fix_messages('message_types/heartbeat.txt', version[:data_dictionary], version[:session_dictionary]) do |hash|
            expect(["Heartbeat", "HEARTBEAT"].include?(hash["MsgType"])).to be true

            expect(hash["BeginString"]).to be_a String
            expect(hash["SendingTime"]).to be_a String
            expect(hash["CheckSum"]).to be_a String
            expect([String, Fixnum].include?(hash["BodyLength"].class)).to be true
            expect([String, Fixnum].include?(hash["MsgSeqNum"].class)).to be true
            expect(["BANZAI", "EXEC"].include?(hash["TargetCompID"])).to be true
            expect(["BANZAI", "EXEC"].include?(hash["SenderCompID"])).to be true
          end
        end
      end
    end

    context 'logon' do
      it 'can parse these' do
        [fix_4, fix_5].each do |version|
          should_parse_fix_messages('message_types/logon.txt', version[:data_dictionary], version[:session_dictionary]) do |hash|
            expect(["Logon", "LOGON"].include?(hash["MsgType"])).to be true

            expect(hash["BeginString"]).to be_a String
            expect([String, Fixnum].include?(hash["HeartBtInt"].class)).to be true

            expect(["BANZAI", "EXEC"].include?(hash["TargetCompID"])).to be true
            expect(["BANZAI", "EXEC"].include?(hash["SenderCompID"])).to be true
          end
        end
      end
    end

    context 'execution_report' do
      it 'can parse these' do
        [fix_4, fix_5].each do |version|
          should_parse_fix_messages('message_types/execution_report.txt', version[:data_dictionary], version[:session_dictionary]) do |hash|
            expect(["ExecutionReport"].include?(hash["MsgType"])).to be true

            expect(hash["ClOrdID"]).to be_a String
            expect(hash["Symbol"]).to be_a String

            expect(["NEW", "FILLED"].include?(hash["OrdStatus"])).to be true
            expect(["BUY", "SELL"].include?(hash["Side"])).to be true

            expect([String, Float].include?(hash["LastPx"].class)).to be true
            # NOTE: This field was changed between FIX 4 / 5
            # expect([String, Float].include?(hash["LastShares"].class)).to be true
            expect([String, Float].include?(hash["OrderQty"].class)).to be true

            expect(hash["TargetSubID"]).to be_a(String) if hash["TargetSubID"].present?

            expect(["BANZAI", "EXEC", "ANOTHER_INC"].include?(hash["TargetCompID"])).to be true
            expect(["BANZAI", "EXEC", "DUMMY_INC"].include?(hash["SenderCompID"])).to be true
          end
        end
      end
    end

    context 'new order single' do
      it 'can parse these' do
        [fix_4, fix_5].each do |version|
          should_parse_fix_messages('message_types/new_order_single.txt', version[:data_dictionary], version[:session_dictionary]) do |hash|
            expect(hash["MsgType"]).to eq "NewOrderSingle"

            expect(hash["ClOrdID"]).to be_a String
            expect(hash["Symbol"]).to be_a String
            expect(hash["TimeInForce"]).to be_a String
            expect(hash["OrderQty"]).to be_a Float

            expect(["MARKET", "LIMIT"].include?(hash["OrdType"])).to be true
            expect(["BUY", "SELL"].include?(hash["Side"])).to be true

            expect(["BANZAI", "EXEC", "DUMMY_INC"].include?(hash["TargetCompID"])).to be true
            expect(["BANZAI", "EXEC", "ANOTHER_INC"].include?(hash["SenderCompID"])).to be true
          end
        end
      end
    end

    context 'order cancel request' do
      it 'can parse these' do
        [fix_4, fix_5].each do |version|
          should_parse_fix_messages('message_types/order_cancel_request.txt', version[:data_dictionary], version[:session_dictionary]) do |hash|
            expect(hash["MsgType"]).to eq "OrderCancelRequest"

            expect(hash["ClOrdID"]).to be_a String
            expect(hash["OrigClOrdID"]).to be_a String
            expect(hash["Symbol"]).to be_a String

            expect(hash["OrderQty"]).to be_a(Float) if hash["OrderQty"].present?
            expect(["FUTURE"].include?(hash["SecurityType"])).to be(true) if hash["SecurityType"].present?

            expect(["BUY", "SELL"].include?(hash["Side"])).to be true

            expect(["BANZAI", "EXEC", "DUMMY_INC"].include?(hash["TargetCompID"])).to be true
            expect(["BANZAI", "EXEC", "ANOTHER_INC"].include?(hash["SenderCompID"])).to be true
          end
        end
      end
    end

    context 'rejects' do
      it 'can parse these' do
        [fix_4, fix_5].each do |version|
          should_parse_fix_messages('message_types/reject.txt', version[:data_dictionary], version[:session_dictionary]) do |hash|
            expect(["Reject", "REJECT"].include?(hash["MsgType"])).to be true
            expect(hash["Text"]).to eq "Unsupported message type"

            expect(["BANZAI", "EXEC"].include?(hash["TargetCompID"])).to be true
            expect(["BANZAI", "EXEC"].include?(hash["SenderCompID"])).to be true
          end
        end
      end
    end

    context 'market data snapshots' do
      it 'can parse these' do
        [fix_4, fix_5].each do |version|
          should_parse_fix_messages('message_types/market_data_snapshot.txt', version[:data_dictionary], version[:session_dictionary]) do |hash|
            expect(["MarketDataSnapshotFullRefresh", "REJECT"].include?(hash["MsgType"])).to be true

            expect(hash["NoMDEntries"]).to be_a(Array)
            expect(hash["NoMDEntries"].first).to be_a(Hash)
            expect(hash["NoMDEntries"].first["MDEntryPx"]).to be_a(Float)
            expect(hash["NoMDEntries"].first["MDEntrySize"]).to be_a(Float) if hash["NoMDEntries"].first["MDEntrySize"].present?

            expect(["ANOTHER_INC"].include?(hash["TargetCompID"])).to be true
            expect(["DUMMY_INC"].include?(hash["SenderCompID"])).to be true
          end
        end
      end
    end

    context 'human-readable group enums' do
      it 'can parse these' do
        [fix_4, fix_5].each do |version|
          should_parse_fix_messages('message_types/market_data_snapshot.txt', version[:data_dictionary], version[:session_dictionary]) do |hash|
            expect(["BID", "OFFER", "INDEX_VALUE"].include?(hash["NoMDEntries"].first["MDEntryType"])).to be true
          end
        end
      end
    end
  end
end
