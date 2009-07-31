require File.dirname(__FILE__) + '/helper'

def expect_session_data_for(controller)
  HoptoadNotifier.sender.expects(:send_to_hoptoad).with do |yaml|
    data = YAML.load(yaml)
    assert data.respond_to?(:to_hash), "The notifier needs a hash"
    assert_not_nil data['session'], "No session was set"
    assert_not_nil data['session']['data'], "No session data was set"
    true
  end.returns(stub_notice)
  @controller.stubs(:rescue_action_in_public_without_hoptoad)
end

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

  should "send session data to hoptoad when the session has @data" do
    stub_public_request!
    expect_session_data_for(@controller)
    @request = ActionController::TestRequest.new
    @request.action = 'do_raise'
    @request.session.instance_variable_set("@data", { :message => 'Hello' })
    @response = ActionController::TestResponse.new
    @controller.process(@request, @response)
  end

  should "send session data to hoptoad when the session responds to to_hash" do
    stub_public_request!
    expect_session_data_for(@controller)
    @request = ActionController::TestRequest.new
    @request.action = 'do_raise'
    @request.session.stubs(:to_hash).returns(:message => 'Hello')
    @response = ActionController::TestResponse.new
    @controller.process(@request, @response)
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

      context "and configured to ignore_by_filter" do
        setup do
          HoptoadNotifier.configuration.ignore_by_filter do |exception_data|
            if exception_data[:error_class] == "RuntimeError"
              true if exception_data[:request][:params]['blah'] == 'skip'
            end
          end
        end

        should "ignore exceptions based on param data" do
          @controller.expects(:rescue_action_in_public_without_hoptoad)
          assert_nothing_raised do
            request("do_raise", "get", nil, :blah => 'skip')
          end
          assert_caught_and_not_sent
        end
      end

      context "and configured to ignore additional exceptions" do
        setup do
          HoptoadNotifier.configuration.ignore << ActiveRecord::StatementInvalid
        end

        should "still ignore default exceptions" do
          @controller.expects(:rescue_action_in_public_without_hoptoad)
          assert_nothing_raised do
            request("do_raise_ignored")
          end
          assert_caught_and_not_sent
        end

        should "ignore specified exceptions" do
          @controller.expects(:rescue_action_in_public_without_hoptoad)
          assert_nothing_raised do
            request("do_raise_not_ignored")
          end
          assert_caught_and_not_sent
        end

        should "not ignore unspecified, non-default exceptions" do
          @controller.expects(:rescue_action_in_public_without_hoptoad)
          assert_nothing_raised do
            request("do_raise")
          end
          assert_caught_and_sent
        end
      end

      context "and configured to ignore only certain exceptions" do
        setup do
          HoptoadNotifier.configuration.ignore_only = [ActiveRecord::StatementInvalid]
        end

        should "no longer ignore default exceptions" do
          @controller.expects(:rescue_action_in_public_without_hoptoad)
          assert_nothing_raised do
            request("do_raise_ignored")
          end
          assert_caught_and_sent
        end

        should "ignore specified exceptions" do
          @controller.expects(:rescue_action_in_public_without_hoptoad)
          assert_nothing_raised do
            request("do_raise_not_ignored")
          end
          assert_caught_and_not_sent
        end

        should "not ignore unspecified, non-default exceptions" do
          @controller.expects(:rescue_action_in_public_without_hoptoad)
          assert_nothing_raised do
            request("do_raise")
          end
          assert_caught_and_sent
        end
      end

      should "ignore exceptions when user agent is being ignored by regular expression" do
        HoptoadNotifier.configuration.ignore_user_agent_only = [/Ignored/]
        @controller.expects(:rescue_action_in_public_without_hoptoad)
        assert_nothing_raised do
          request("do_raise", :get, 'IgnoredUserAgent')
        end
        assert_caught_and_not_sent
      end

      should "ignore exceptions when user agent is being ignored by string" do
        HoptoadNotifier.configuration.ignore_user_agent_only = ['IgnoredUserAgent']
        @controller.expects(:rescue_action_in_public_without_hoptoad)
        assert_nothing_raised do
          request("do_raise", :get, 'IgnoredUserAgent')
        end
        assert_caught_and_not_sent
      end

      should "not ignore exceptions when user agent is not being ignored" do
        @controller.expects(:rescue_action_in_public_without_hoptoad)
        assert_nothing_raised do
          request("do_raise")
        end
        assert_caught_and_sent
      end
    end
  end
end
