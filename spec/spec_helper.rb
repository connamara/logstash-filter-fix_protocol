$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'fix_logstash_plugin'

require 'pry'

Dir[("#{Dir.pwd}/spec/support/**/*.rb")].each { |f| require f }

RSpec.configure do |config|
  config.filter_run :focus
  config.run_all_when_everything_filtered = true

  config.order = :random
end
