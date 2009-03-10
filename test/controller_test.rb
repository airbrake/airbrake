require File.dirname(__FILE__) + '/helper'

def should_notify_normally
  should "have inserted its methods into the controller" do
    assert @controller.methods.include?("inform_hoptoad")
  end

  should "prevent raises and send the error to hoptoad" do
    @controller.expects(:notify_hoptoad)
    @controller.expects(:rescue_action_in_public_without_hoptoad)
    assert_nothing_raised do
      request("do_raise")
    end
  end

  should "allow a non-raising action to complete" do
    assert_nothing_raised do
      request("do_not_raise")
    end
  end

  should "allow manual sending of exceptions" do
    @controller.expects(:notify_hoptoad)
    @controller.expects(:rescue_action_in_public_without_hoptoad).never
    assert_nothing_raised do
      request("manual_notify")
    end
  end

  should "disable manual sending of exceptions in a non-public (development or test) environment" do
    @controller.stubs(:public_environment?).returns(false)
    @controller.expects(:send_to_hoptoad).never
    @controller.expects(:rescue_action_in_public_without_hoptoad).never
    assert_nothing_raised do
      request("manual_notify")
    end
  end

  should "send even ignored exceptions if told manually" do
    @controller.expects(:notify_hoptoad)
    @controller.expects(:rescue_action_in_public_without_hoptoad).never
    assert_nothing_raised do
      request("manual_notify_ignored")
    end
  end

  should "ignore default exceptions" do
    @controller.expects(:notify_hoptoad).never
    @controller.expects(:rescue_action_in_public_without_hoptoad)
    assert_nothing_raised do
      request("do_raise_ignored")
    end
  end

  should "filter non-serializable data" do
    File.open(__FILE__) do |file|
      assert_equal( {:ghi => "789"},
                   @controller.send(:clean_non_serializable_data, :ghi => "789", :class => Class.new, :file => file) )
    end
  end

  should "apply all params, environment and technical filters" do
    params_hash = {:abc => 123}
    environment_hash = {:def => 456}
    backtrace_data = :backtrace_data

    raw_notice = {:request => {:params => params_hash}, 
                  :environment => environment_hash,
                  :backtrace => backtrace_data}

    processed_notice = {:backtrace => :backtrace_data, 
                        :request => {:params => :params_data}, 
                        :environment => :environment_data}

    @controller.expects(:clean_hoptoad_backtrace).with(backtrace_data).returns(:backtrace_data)
    @controller.expects(:clean_hoptoad_params).with(params_hash).returns(:params_data)
    @controller.expects(:clean_hoptoad_environment).with(environment_hash).returns(:environment_data)
    @controller.expects(:clean_non_serializable_data).with(processed_notice).returns(:serializable_data)

    assert_equal(:serializable_data, @controller.send(:clean_notice, raw_notice))
  end
end

def should_auto_include_catcher
  should "auto-include for ApplicationController" do
    assert ApplicationController.include?(HoptoadNotifier::Catcher)
  end
end

class ControllerTest < Test::Unit::TestCase
  context "Hoptoad inclusion" do
    should "be able to occur even outside Rails controllers" do
      assert_nothing_raised do
        class MyHoptoad
          include HoptoadNotifier::Catcher
        end
      end
      my = MyHoptoad.new
      assert my.respond_to?(:notify_hoptoad)
    end

    context "when auto-included" do
      setup do
        class ::ApplicationController < ActionController::Base
        end

        class ::AutoIncludeController < ::ApplicationController
          include TestMethods
          def rescue_action e
            rescue_action_in_public e
          end
        end

        HoptoadNotifier.ignore_only = HoptoadNotifier::IGNORE_DEFAULT
        @controller = ::AutoIncludeController.new
        @controller.stubs(:public_environment?).returns(true)
        @controller.stubs(:send_to_hoptoad)

        HoptoadNotifier.configure do |config|
          config.api_key = "1234567890abcdef"
        end
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
        HoptoadNotifier.ignore_only = HoptoadNotifier::IGNORE_DEFAULT
        @controller.stubs(:public_environment?).returns(true)
        @controller.stubs(:send_to_hoptoad)
      end

      should_notify_normally

      context "and configured to ignore additional exceptions" do
        setup do
          HoptoadNotifier.ignore << ActiveRecord::StatementInvalid
        end

        should "still ignore default exceptions" do
          @controller.expects(:notify_hoptoad).never
          @controller.expects(:rescue_action_in_public_without_hoptoad)
          assert_nothing_raised do
            request("do_raise_ignored")
          end
        end

        should "ignore specified exceptions" do
          @controller.expects(:notify_hoptoad).never
          @controller.expects(:rescue_action_in_public_without_hoptoad)
          assert_nothing_raised do
            request("do_raise_not_ignored")
          end
        end

        should "not ignore unspecified, non-default exceptions" do
          @controller.expects(:notify_hoptoad)
          @controller.expects(:rescue_action_in_public_without_hoptoad)
          assert_nothing_raised do
            request("do_raise")
          end
        end
      end

      context "and configured to ignore only certain exceptions" do
        setup do
          HoptoadNotifier.ignore_only = [ActiveRecord::StatementInvalid]
        end

        should "no longer ignore default exceptions" do
          @controller.expects(:notify_hoptoad)
          @controller.expects(:rescue_action_in_public_without_hoptoad)
          assert_nothing_raised do
            request("do_raise_ignored")
          end
        end

        should "ignore specified exceptions" do
          @controller.expects(:notify_hoptoad).never
          @controller.expects(:rescue_action_in_public_without_hoptoad)
          assert_nothing_raised do
            request("do_raise_not_ignored")
          end
        end

        should "not ignore unspecified, non-default exceptions" do
          @controller.expects(:notify_hoptoad)
          @controller.expects(:rescue_action_in_public_without_hoptoad)
          assert_nothing_raised do
            request("do_raise")
          end
        end
      end

      context "and configured to ignore certain user agents" do
        setup do
          HoptoadNotifier.ignore_user_agent << /Ignored/
          HoptoadNotifier.ignore_user_agent << 'IgnoredUserAgent'
        end

        should "ignore exceptions when user agent is being ignored" do
          @controller.expects(:notify_hoptoad).never
          @controller.expects(:rescue_action_in_public_without_hoptoad)
          assert_nothing_raised do
            request("do_raise", :get, 'IgnoredUserAgent')
          end
        end

        should "ignore exceptions when user agent is being ignored (regexp)" do
          HoptoadNotifier.ignore_user_agent_only = [/Ignored/]
          @controller.expects(:notify_hoptoad).never
          @controller.expects(:rescue_action_in_public_without_hoptoad)
          assert_nothing_raised do
            request("do_raise", :get, 'IgnoredUserAgent')
          end
        end

        should "ignore exceptions when user agent is being ignored (string)" do
          HoptoadNotifier.ignore_user_agent_only = ['IgnoredUserAgent']
          @controller.expects(:notify_hoptoad).never
          @controller.expects(:rescue_action_in_public_without_hoptoad)
          assert_nothing_raised do
            request("do_raise", :get, 'IgnoredUserAgent')
          end
        end

        should "not ignore exceptions when user agent is not being ignored" do
          @controller.expects(:notify_hoptoad)
          @controller.expects(:rescue_action_in_public_without_hoptoad)
          assert_nothing_raised do
            request("do_raise")
          end
        end
      end
    end
  end
end
