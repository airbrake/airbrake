require File.dirname(__FILE__) + '/helper'

class ConfigurationTest < ActiveSupport::TestCase
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
        config.ignore_user_agent << 'UserAgentString'
        config.ignore_user_agent << /UserAgentRegexp/
        config.proxy_host = 'proxyhost1'
        config.proxy_port = '80'
        config.proxy_user = 'user'
        config.proxy_pass = 'secret'
        config.http_open_timeout = 2
        config.http_read_timeout = 5
      end

      assert_equal "host",              HoptoadNotifier.host
      assert_equal 3333,                HoptoadNotifier.port
      assert_equal true,                HoptoadNotifier.secure
      assert_equal "1234567890abcdef",  HoptoadNotifier.api_key
      assert_equal 'proxyhost1',        HoptoadNotifier.proxy_host
      assert_equal '80',                HoptoadNotifier.proxy_port
      assert_equal 'user',              HoptoadNotifier.proxy_user
      assert_equal 'secret',            HoptoadNotifier.proxy_pass
      assert_equal 2,                   HoptoadNotifier.http_open_timeout
      assert_equal 5,                   HoptoadNotifier.http_read_timeout
      assert_equal (HoptoadNotifier::IGNORE_USER_AGENT_DEFAULT + ['UserAgentString', /UserAgentRegexp/]), HoptoadNotifier.ignore_user_agent
      assert_equal (HoptoadNotifier::IGNORE_DEFAULT + [RuntimeError]), HoptoadNotifier.ignore
    end

    should "set a default host" do
      HoptoadNotifier.instance_variable_set("@host",nil)
      assert_equal "hoptoadapp.com", HoptoadNotifier.host
    end

    should "remove notifier trace when cleaning backtrace" do
      HoptoadNotifier.configure {}
      options = HoptoadNotifier.default_notice_options

      options = @controller.send(:normalize_notice, {})
      dirty_backtrace = @controller.send(:clean_hoptoad_backtrace, options[:backtrace])

      dirty_backtrace.each do |line|
        assert_no_match /lib\/hoptoad_notifier.rb/, line
      end
    end

    should "add filters to the backtrace_filters" do
      assert_difference "HoptoadNotifier.backtrace_filters.length", 5 do
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
end
