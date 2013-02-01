require File.expand_path '../helper', __FILE__

require 'airbrake/rails/controller_methods'

class TestController
  include Airbrake::Rails::ControllerMethods

  def current_user
    nil
  end
end

class ControllerMethodsTest < Test::Unit::TestCase
  context "#airbrake_current_user" do
    setup do

      NilClass.class_eval do
        @@called = false

        def self.called
          !! @@called
        end

        def id
          @@called = true
        end
      end

      @controller = TestController.new
    end

    should "not call #id on NilClass" do
      @controller.send(:airbrake_current_user)
      assert_equal false, NilClass.called
    end
  end
end
