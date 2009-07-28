require File.dirname(__FILE__) + '/helper'

class ConfigurationTest < Test::Unit::TestCase
  should "provide default values" do
    assert_config_default :proxy_host,          nil
    assert_config_default :proxy_port,          nil
    assert_config_default :proxy_user,          nil
    assert_config_default :proxy_pass,          nil
    assert_config_default :secure,              false
    assert_config_default :host,                'hoptoadapp.com'
    assert_config_default :http_open_timeout,   2
    assert_config_default :http_read_timeout,   5
    assert_config_default :ignore_by_filters,   []
    assert_config_default :params_filters,
                          HoptoadNotifier::Configuration::DEFAULT_PARAMS_FILTERS
    assert_config_default :environment_filters, []
    assert_config_default :backtrace_filters,
                          HoptoadNotifier::Configuration::DEFAULT_BACKTRACE_FILTERS
    assert_config_default :ignore,
                          HoptoadNotifier::Configuration::IGNORE_DEFAULT
  end

  should "provide default values for secure connections" do
    config = HoptoadNotifier::Configuration.new
    config.secure = true
    assert_config_default :port,     443,     config
    assert_config_default :protocol, 'https', config
  end

  should "provide default values for insecure connections" do
    config = HoptoadNotifier::Configuration.new
    config.secure = false
    assert_config_default :port,     80,     config
    assert_config_default :protocol, 'http', config
  end

  should "allow values to be overwritten" do
    assert_config_overridable :proxy_host
    assert_config_overridable :proxy_port
    assert_config_overridable :proxy_user
    assert_config_overridable :proxy_pass
    assert_config_overridable :secure
    assert_config_overridable :host
    assert_config_overridable :port
    assert_config_overridable :http_open_timeout
    assert_config_overridable :http_read_timeout
  end

  should "have an api key" do
    assert_config_overridable :api_key
  end

  should "act like a hash" do
    config = HoptoadNotifier::Configuration.new
    config.port = 888
    assert_equal 888, config[:port]
  end

  should "allow param filters to be appended" do
    config = HoptoadNotifier::Configuration.new
    original_filters = config.params_filters.dup
    new_filter = 'hello'
    config.params_filters << new_filter
    assert_same_elements original_filters + [new_filter], config.params_filters
  end

  should "allow environment filters to be appended" do
    config = HoptoadNotifier::Configuration.new
    original_filters = config.environment_filters.dup
    new_filter = 'hello'
    config.environment_filters << new_filter
    assert_same_elements original_filters + [new_filter], config.environment_filters
  end

  should "allow backtrace filters to be appended" do
    config = HoptoadNotifier::Configuration.new
    original_filters = config.backtrace_filters.dup
    new_filter = lambda {}
    config.filter_backtrace(&new_filter)
    assert_same_elements original_filters + [new_filter], config.backtrace_filters
  end

  should "allow ignore by filters to be appended" do
    config = HoptoadNotifier::Configuration.new
    original_filters = config.ignore_by_filters.dup
    new_filter = lambda {}
    config.ignore_by_filter(&new_filter)
    assert_same_elements original_filters + [new_filter], config.ignore_by_filters
  end

  should "allow ignored exceptions to be appended" do
    config = HoptoadNotifier::Configuration.new
    original_filters = config.ignore.dup
    new_filter = 'hello'
    config.ignore << new_filter
    assert_same_elements original_filters + [new_filter], config.ignore
  end

  should "allow ignore exceptions to be replaced" do
    config = HoptoadNotifier::Configuration.new
    new_filter = 'hello'
    config.ignore_only = new_filter
    assert_equal [new_filter], config.ignore
  end

  def assert_config_default(option, default_value, config = nil)
    config ||= HoptoadNotifier::Configuration.new
    assert_equal default_value, config.send(option)
  end

  def assert_config_overridable(option, value = 'a value')
    config = HoptoadNotifier::Configuration.new
    config.send(:"#{option}=", value)
    assert_equal value, config.send(option)
  end
end
