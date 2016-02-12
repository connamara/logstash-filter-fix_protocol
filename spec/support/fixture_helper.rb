module FixtureHelper
  def load_fixture(file_name)
    File.expand_path("../../fixtures/#{file_name}", __FILE__)
  end
end

RSpec.configure do |config|
  config.include FixtureHelper
  config.extend FixtureHelper
end
