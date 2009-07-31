require File.dirname(__FILE__) + '/helper'

def should_notify_normally
  should "send even ignored exceptions if told manually" do
    @controller.expects(:rescue_action_in_public_without_hoptoad).never
    assert_nothing_raised do
      request("manual_notify_ignored")
    end
    assert_caught_and_sent
  end

  should "ignore default exceptions" do
    @controller.expects(:rescue_action_in_public_without_hoptoad)
    assert_nothing_raised do
      request("do_raise_ignored")
    end
    assert_caught_and_not_sent
  end
end

def should_auto_include_catcher
  should "auto-include for ApplicationController" do
    assert ApplicationController.include?(HoptoadNotifier::Catcher)
  end
end

class ControllerTest < Test::Unit::TestCase
  def stub_public_request!
    @controller.class.consider_all_requests_local = false
    @controller.stubs(:local_request? => false)
  end

  context "when auto-included" do
    setup do
      HoptoadNotifier.configure do |config|
        config.api_key = "1234567890abcdef"
      end

      class ::ApplicationController < ActionController::Base
      end

      class ::AutoIncludeController < ::ApplicationController
        include TestMethods
        def rescue_action e
          rescue_action_in_public e
        end
      end

      @controller = ::AutoIncludeController.new
      stub_public_request!
      HoptoadNotifier.sender = CollectingSender.new
    end

    context "when included through the configure block" do
      should_auto_include_catcher
      should_notify_normally
    end

    context "when included both through configure and normally" do
      setup do
        class ::AutoIncludeController < ::ApplicationController
          include HoptoadNotifier::Catcher
        end
      end
      should_auto_include_catcher
      should_notify_normally
    end
  end

  context "when the logger is overridden for an action" do
    setup do
      class ::IgnoreActionController < ::ActionController::Base
        include TestMethods
        include HoptoadNotifier::Catcher
        def rescue_action e
          rescue_action_in_public e
        end
        def logger
          super unless action_name == "do_raise"
        end
      end
      reset_config
      ::ActionController::Base.logger = Logger.new(STDOUT)
      @controller = ::IgnoreActionController.new
      @controller.stubs(:public_environment?).returns(true)
      @controller.stubs(:rescue_action_in_public_without_hoptoad)
      HoptoadNotifier.stubs(:environment_info)

      # stubbing out Net::HTTP as well
      @body = 'body'
      @http = stub(:post => @response, :read_timeout= => nil, :open_timeout= => nil, :use_ssl= => nil)
      Net::HTTP.stubs(:new).returns(@http)
    end

    should "work when action is called and request works" do
      @response = stub(:body => @body, :class => Net::HTTPSuccess)
      assert_nothing_raised do
        request("do_raise")
      end
    end

    should "work when action is called and request doesn't work" do
      @response = stub(:body => @body, :class => Net::HTTPError)
      assert_nothing_raised do
        request("do_raise")
      end
    end

    should "work when action is called and hoptoad times out" do
      @http.stubs(:post).raises(TimeoutError)
      assert_nothing_raised do
        request("do_raise")
      end
    end
  end

  context "The hoptoad test controller" do
    setup do
      @controller = ::HoptoadController.new
      class ::HoptoadController
        def rescue_action e
          raise e
        end
      end
    end

    context "with no notifier catcher" do
      should "not prevent raises" do
        assert_raises RuntimeError do
          request("do_raise")
        end
      end

      should "allow a non-raising action to complete" do
        assert_nothing_raised do
          request("do_not_raise")
        end
      end
    end

    context "with the notifier installed" do
      setup do
        class ::HoptoadController
          include HoptoadNotifier::Catcher
          def rescue_action e
            rescue_action_in_public e
          end
        end
        reset_config
        stub_public_request!
        HoptoadNotifier.sender = CollectingSender.new
      end

      should_notify_normally
    end
  end
end
