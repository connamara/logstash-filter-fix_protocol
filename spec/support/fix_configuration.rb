require_relative 'fixture_helper'

module FixConfiguration
  include FixtureHelper

  def fix_5_configuration
    <<-CONFIG
      filter {
        fix_protocol {
          fix_message => message
          session_dictionary_path => "#{ load_fixture("FIXT11.xml") }"
          data_dictionary_path => "#{ load_fixture("FIX50SP1.xml") }"
        }
      }
    CONFIG
  end

  def fix_4_configuration
    <<-CONFIG
      filter {
        fix_protocol {
          fix_message => message
          data_dictionary_path => "#{ load_fixture("FIX42.xml") }"
        }
      }
    CONFIG
  end
end

RSpec.configure do |config|
  config.include FixConfiguration
  config.extend FixConfiguration
end
