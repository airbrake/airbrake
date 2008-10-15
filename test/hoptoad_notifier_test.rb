require 'test/unit'
require 'rubygems'
require 'mocha'
require 'shoulda'
require 'action_controller'
require 'action_controller/test_process'
require 'active_record'
require 'net/http'
require 'net/https'
require File.join(File.dirname(__FILE__), "..", "lib", "hoptoad_notifier")

RAILS_ROOT = File.join( File.dirname(__FILE__), "rails_root" )
RAILS_ENV  = "test"

class HoptoadController < ActionController::Base
  def rescue_action e
    raise e
  end
  
  def do_raise
    raise "Hoptoad"
  end
  
  def do_not_raise
    render :text => "Success"
  end
  
  def do_raise_ignored
    raise ActiveRecord::RecordNotFound.new("404")
  end
  
  def do_raise_not_ignored
    raise ActiveRecord::StatementInvalid.new("Statement invalid")
  end
  
  def manual_notify
    notify_hoptoad(Exception.new)
    render :text => "Success"
  end
  
  def manual_notify_ignored
    notify_hoptoad(ActiveRecord::RecordNotFound.new("404"))
    render :text => "Success"
  end
end

class HoptoadNotifierTest < Test::Unit::TestCase
  def request(action = nil, method = :get)
    @request = ActionController::TestRequest.new({
      "controller" => "hoptoad",
      "action"     => action ? action.to_s : "",
      "_method"    => method.to_s
    })
    @response = ActionController::TestResponse.new
    @controller.process(@request, @response)
  end
  
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
  end
  
  context "HoptoadNotifier configuration" do
    setup do
      @controller = HoptoadController.new
      class ::HoptoadController
        include HoptoadNotifier::Catcher
        def rescue_action e
          rescue_action_in_public e
        end
      end
      assert @controller.methods.include?("notify_hoptoad")
    end

    should "be done with a block" do
      HoptoadNotifier.configure do |config|
        config.host = "host"
        config.port = 3333
        config.secure = true
        config.api_key = "1234567890abcdef"
        config.ignore << [ RuntimeError ]
      end
      
      assert_equal "host",              HoptoadNotifier.host
      assert_equal 3333,                HoptoadNotifier.port
      assert_equal true,                HoptoadNotifier.secure
      assert_equal "1234567890abcdef",  HoptoadNotifier.api_key
      assert_equal (HoptoadNotifier::IGNORE_DEFAULT + [RuntimeError]), HoptoadNotifier.ignore
    end

    should "set a default host" do
      HoptoadNotifier.instance_variable_set("@host",nil)
      assert_equal "hoptoadapp.com", HoptoadNotifier.host
    end
    
    should "add filters to the backtrace_filters" do
      assert_difference "HoptoadNotifier.backtrace_filters.length" do
        HoptoadNotifier.configure do |config|
          config.filter_backtrace do |line|
            line = "1234"
          end
        end
      end
      
      assert_equal %w( 1234 1234 ), @controller.send(:clean_hoptoad_backtrace, %w( foo bar ))
    end
    
    should "use standard rails logging filters on params and env" do
      ::HoptoadController.class_eval do
        filter_parameter_logging :ghi
      end
 
      expected = {"notice" => {"request" => {"params" => {"abc" => "123", "def" => "456", "ghi" => "[FILTERED]"}},
                             "environment" => {"abc" => "123", "ghi" => "[FILTERED]"}}}
      notice   = {"notice" => {"request" => {"params" => {"abc" => "123", "def" => "456", "ghi" => "789"}},
                             "environment" => {"abc" => "123", "ghi" => "789"}}}
      assert @controller.respond_to?(:filter_parameters)
      assert_equal( expected[:notice], @controller.send(:clean_notice, notice)[:notice] )
    end

    should "add filters to the params filters" do
      assert_difference "HoptoadNotifier.params_filters.length", 2 do
        HoptoadNotifier.configure do |config|
          config.params_filters << "abc"
          config.params_filters << "def"
        end
      end

      assert HoptoadNotifier.params_filters.include?( "abc" )
      assert HoptoadNotifier.params_filters.include?( "def" )
      
      assert_equal( {:abc => "[FILTERED]", :def => "[FILTERED]", :ghi => "789"},
                    @controller.send(:clean_hoptoad_params, :abc => "123", :def => "456", :ghi => "789" ) )
    end

    should "add filters to the environment filters" do
      assert_difference "HoptoadNotifier.environment_filters.length", 2 do
        HoptoadNotifier.configure do |config|
          config.environment_filters << "secret"
          config.environment_filters << "supersecret"
        end
      end

      assert HoptoadNotifier.environment_filters.include?( "secret" )
      assert HoptoadNotifier.environment_filters.include?( "supersecret" )
      
      assert_equal( {:secret => "[FILTERED]", :supersecret => "[FILTERED]", :ghi => "789"},
                    @controller.send(:clean_hoptoad_environment, :secret => "123", :supersecret => "456", :ghi => "789" ) )
    end

    should "have at default ignored exceptions" do
      assert HoptoadNotifier::IGNORE_DEFAULT.any?
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
    end
  end
  
  context "Sending a notice" do
    context "with an exception" do
      setup do
        @sender    = HoptoadNotifier::Sender.new
        @backtrace = caller
        @exception = begin
          raise
        rescue => caught_exception
          caught_exception
        end
        @options   = {:error_message => "123",
                      :backtrace => @backtrace}
        HoptoadNotifier.instance_variable_set("@backtrace_filters", [])
        HoptoadNotifier::Sender.expects(:new).returns(@sender)
        @sender.stubs(:public_environment?).returns(true)
      end

      should "send as if it were a normally caught exception" do
        @sender.expects(:notify_hoptoad).with(@exception)
        HoptoadNotifier.notify(@exception)
      end

      should "make sure the exception is munged into a hash" do
        options = HoptoadNotifier.default_notice_options.merge({
          :backtrace     => @exception.backtrace,
          :environment   => ENV.to_hash,
          :error_class   => @exception.class.name,
          :error_message => "#{@exception.class.name}: #{@exception.message}",
          :api_key       => HoptoadNotifier.api_key,
        })
        @sender.expects(:send_to_hoptoad).with(:notice => options)
        HoptoadNotifier.notify(@exception)
      end
      
      should "parse massive one-line exceptions into multiple lines" do
        @original_backtrace = "one big line\n   separated\n      by new lines\nand some spaces"
        @expected_backtrace = ["one big line", "separated", "by new lines", "and some spaces"]
        @exception.set_backtrace [@original_backtrace]
        
        options = HoptoadNotifier.default_notice_options.merge({
          :backtrace     => @expected_backtrace,
          :environment   => ENV.to_hash,
          :error_class   => @exception.class.name,
          :error_message => "#{@exception.class.name}: #{@exception.message}",
          :api_key       => HoptoadNotifier.api_key,
        })
        
        @sender.expects(:send_to_hoptoad).with(:notice => options)
        HoptoadNotifier.notify(@exception)
      end
    end

    context "without an exception" do
      setup do
        @sender    = HoptoadNotifier::Sender.new
        @backtrace = caller
        @options   = {:error_message => "123",
                      :backtrace => @backtrace}
        HoptoadNotifier::Sender.expects(:new).returns(@sender)
      end

      should "send sensible defaults" do
        @sender.expects(:notify_hoptoad).with(@options)
        HoptoadNotifier.notify(:error_message => "123", :backtrace => @backtrace)
      end
    end
  end
end
