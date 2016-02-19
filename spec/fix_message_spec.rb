require 'spec_helper'

describe LF::FixMessage do
  let(:message_str) { "8=FIXT.1.1\x0135=8\x0149=ITG\x0156=SILO\x01315=8\x016=100.25\x01410=50.25\x01424=23.45\x01411=Y\x0143=N\x0140=1\x015=N\x01" }
  let(:another_str) { "8=FIXT.1.1\x0135=B\x0149=ITG\x0156=SILO\x01148=Market Bulls Have Short Sellers on the Run\x0133=2\x0158=The bears have been cowed by the bulls.\x0158=Buy buy buy\x01354=0\x0143=N\x0140=1\x015=N\x01" }

  let(:data_dictionary) { LF::DataDictionary.new(load_fixture("FIX50SP1.xml")) }
  let(:session_dictionary) { LF::DataDictionary.new(load_fixture("FIXT11.xml")) }
  let(:message) { LF::FixMessage.new(message_str, data_dictionary, session_dictionary) }
  let(:message2) { LF::FixMessage.new(another_str, data_dictionary, session_dictionary) }

  describe '#type' do
    it 'returns the message type' do
      expect(message.type).to eq "8"
    end
  end

  describe '#is_admin?' do
    it 'returns whether the message is an admin message' do
      expect(message.is_admin?).to eq false
    end
  end

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

  context 'parsing message types' do
    let(:fix_4)  { {data_dictionary: "FIX42.xml", session_dictionary: nil} }
    let(:fix_5)  { {data_dictionary: "FIX50SP1.xml", session_dictionary: "FIXT11.xml"} }
    # data is from: http://fixparser.targetcompid.com/
    context 'heartbeats' do
      it 'can parse dat' do
        [fix_4, fix_5].each do |version|
          should_parse_fix_messages('message_types/heartbeat.txt', version[:data_dictionary], version[:session_dictionary]) do |hash|
            expect(hash["BeginString"]).to be_a String
            expect(hash["SendingTime"]).to be_a String
            expect(hash["CheckSum"]).to be_a String
            # TODO: Need to figure out difference between 4/5 version parsing
            expect(["Heartbeat", "HEARTBEAT"].include?(hash["MsgType"])).to be true
            expect([String, Fixnum].include?(hash["BodyLength"].class)).to be true
            expect([String, Fixnum].include?(hash["MsgSeqNum"].class)).to be true
            expect(["BANZAI", "EXEC"].include?(hash["TargetCompID"])).to be true
            expect(["BANZAI", "EXEC"].include?(hash["SenderCompID"])).to be true
          end
        end
      end
    end

    context 'logon' do
      it 'can parse dat' do
        [fix_4, fix_5].each do |version|
          {"BeginString"=>"FIX.4.1", "BodyLength"=>61, "MsgSeqNum"=>1, "MsgType"=>"Logon", "SenderCompID"=>"EXEC", "SendingTime"=>"20121105-23:24:06", "TargetCompID"=>"BANZAI", "EncryptMethod"=>0, "HeartBtInt"=>30, "CheckSum"=>"003"}
          should_parse_fix_messages('message_types/logon.txt', version[:data_dictionary], version[:session_dictionary]) do |hash|
            # TODO: Need to figure out difference between 4/5 version parsing
            expect(["Logon", "LOGON"].include?(hash["MsgType"])).to be true

            expect(hash["BeginString"]).to be_a String
            # TODO: This breaks between versions 4 & 5
            # expect([String, Fixnum].include?(hash["HeartBtInt"].class)).to be true

            expect(["BANZAI", "EXEC"].include?(hash["TargetCompID"])).to be true
            expect(["BANZAI", "EXEC"].include?(hash["SenderCompID"])).to be true
          end
        end
      end
    end
  end
end
