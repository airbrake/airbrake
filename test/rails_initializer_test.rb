require File.expand_path '../helper', __FILE__

require 'airbrake/rails'

class RailsInitializerTest < Test::Unit::TestCase
  include DefinesConstants

  should "trigger use of Rails' logger if logger isn't set and Rails' logger exists" do
    rails = Module.new do
      def self.logger
        "RAILS LOGGER"
      end
    end
    define_constant("Rails", rails)
    Airbrake::Rails.initialize
    assert_equal "RAILS LOGGER", Airbrake.logger
  end

  should "trigger use of Rails' default logger if logger isn't set and Rails.logger doesn't exist" do
    define_constant("RAILS_DEFAULT_LOGGER", "RAILS DEFAULT LOGGER")

    Airbrake::Rails.initialize
    assert_equal "RAILS DEFAULT LOGGER", Airbrake.logger
  end

  should "allow overriding of the logger if already assigned" do
    define_constant("RAILS_DEFAULT_LOGGER", "RAILS DEFAULT LOGGER")
    Airbrake::Rails.initialize

    Airbrake.configure(true) do |config|
      config.logger = "OVERRIDDEN LOGGER"
    end

    assert_equal "OVERRIDDEN LOGGER", Airbrake.logger
  end
end
