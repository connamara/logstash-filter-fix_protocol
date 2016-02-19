$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'pry'

Dir[("#{Dir.pwd}/spec/support/**/*.rb")].each { |f| require f }

# Base config
RSpec.configure do |config|
  config.filter_run :focus
  config.run_all_when_everything_filtered = true

  config.order = :random
end

LF = LogStash::Filters
