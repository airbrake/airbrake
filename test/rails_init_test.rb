require File.dirname(__FILE__) + '/helper'
require File.join(File.dirname(__FILE__), '..', 'lib', 'hoptoad_notifier', 'rails_init')

class RailsInitTest < Test::Unit::TestCase
  include DefinesConstants

  should "trigger use of Rails' logger if logger isn't set and Rails' logger exists" do
    rails = Module.new do
      def self.logger
        "RAILS LOGGER"
      end
    end
    define_constant("Rails", rails)
    HoptoadNotifier::RailsInit.new
    assert_equal "RAILS LOGGER", HoptoadNotifier.logger
  end

  should "trigger use of Rails' default logger if logger isn't set and Rails.logger doesn't exist" do
    define_constant("RAILS_DEFAULT_LOGGER", "RAILS DEFAULT LOGGER")

    HoptoadNotifier::RailsInit.new
    assert_equal "RAILS DEFAULT LOGGER", HoptoadNotifier.logger
  end

  should "allow overriding of the logger if already assigned" do
    define_constant("RAILS_DEFAULT_LOGGER", "RAILS DEFAULT LOGGER")
    HoptoadNotifier::RailsInit.new

    HoptoadNotifier.configure(true) do |config|
      config.logger = "OVERRIDDEN LOGGER"
    end

    assert_equal "OVERRIDDEN LOGGER", HoptoadNotifier.logger
  end
end
