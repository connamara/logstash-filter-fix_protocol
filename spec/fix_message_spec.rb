require 'spec_helper'

describe LogStash::Filters::FixMessage do
  let(:message_str) { "8=FIXT.1.1\x0135=8\x0149=ITG\x0156=SILO\x01315=8\x016=100.25\x01410=50.25\x01424=23.45\x01411=Y\x0143=N\x0140=1\x015=N\x01" }
  let(:another_str) { "8=FIXT.1.1\x0135=B\x0149=ITG\x0156=SILO\x01148=Market Bulls Have Short Sellers on the Run\x0133=2\x0158=The bears have been cowed by the bulls.\x0158=Buy buy buy\x01354=0\x0143=N\x0140=1\x015=N\x01" }

  let(:filter) do
    LogStash::Filters::FixMessageFilter.configure do |config|
      # should give absolute path to FIX data dictionary
      # TODO: Revisit this once we know how folks will configure this
      # config.data_dictionary_path = load_fixture("FIX42.xml")
      config.session_dictionary_path = load_fixture("FIXT11.xml")
      config.data_dictionary_path = load_fixture("FIX50SP1.xml")
    end

    LogStash::Filters::FixMessageFilter.new
  end

  let(:message)  { LogStash::Filters::FixMessage.new(message_str, filter.data_dictionary, filter.session_dictionary) }
  let(:message2) { LogStash::Filters::FixMessage.new(another_str, filter.data_dictionary, filter.session_dictionary) }

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
end
