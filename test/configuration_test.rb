require File.expand_path '../helper', __FILE__

class ConfigurationTest < Test::Unit::TestCase

  include DefinesConstants

  should "provide default values" do
    assert_config_default :proxy_host,          nil
    assert_config_default :proxy_port,          nil
    assert_config_default :proxy_user,          nil
    assert_config_default :proxy_pass,          nil
    assert_config_default :project_root,        nil
    assert_config_default :environment_name,    nil
    assert_config_default :logger,              nil
    assert_config_default :notifier_version,    Airbrake::VERSION
    assert_config_default :notifier_name,       'Airbrake Notifier'
    assert_config_default :notifier_url,        'https://github.com/airbrake/airbrake'
    assert_config_default :secure,              false
    assert_config_default :host,                'api.airbrake.io'
    assert_config_default :http_open_timeout,   2
    assert_config_default :http_read_timeout,   5
    assert_config_default :ignore_by_filters,   []
    assert_config_default :ignore_user_agent,   []
    assert_config_default :params_filters,
                          Airbrake::Configuration::DEFAULT_PARAMS_FILTERS
    assert_config_default :backtrace_filters,
                          Airbrake::Configuration::DEFAULT_BACKTRACE_FILTERS
    assert_config_default :ignore,
                          Airbrake::Configuration::IGNORE_DEFAULT
    assert_config_default :development_lookup, true
    assert_config_default :framework, 'Standalone'
    assert_config_default :async, nil
  end

  should "set GirlFriday-callable for async=true" do
    config = Airbrake::Configuration.new
    config.async = true
    assert config.async.respond_to?(:call)
  end

  should "provide default values for secure connections" do
    config = Airbrake::Configuration.new
    config.secure = true
    assert_equal 443, config.port
    assert_equal 'https', config.protocol
  end

  should "provide default values for insecure connections" do
    config = Airbrake::Configuration.new
    config.secure = false
    assert_equal 80, config.port
    assert_equal 'http', config.protocol
  end

  should "not cache inferred ports" do
    config = Airbrake::Configuration.new
    config.secure = false
    config.port
    config.secure = true
    assert_equal 443, config.port
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
    assert_config_overridable :project_root
    assert_config_overridable :notifier_version
    assert_config_overridable :notifier_name
    assert_config_overridable :notifier_url
    assert_config_overridable :environment_name
    assert_config_overridable :development_lookup
    assert_config_overridable :logger
    assert_config_overridable :async
  end

  should "have an api key" do
    assert_config_overridable :api_key
  end

  should "act like a hash" do
    config = Airbrake::Configuration.new
    hash = config.to_hash
    [:api_key, :backtrace_filters, :development_environments,
     :environment_name, :host, :http_open_timeout,
     :http_read_timeout, :ignore, :ignore_by_filters, :ignore_user_agent,
     :notifier_name, :notifier_url, :notifier_version, :params_filters,
     :project_root, :port, :protocol, :proxy_host, :proxy_pass, :proxy_port,
     :proxy_user, :secure, :development_lookup, :async].each do |option|
      assert_equal config[option], hash[option], "Wrong value for #{option}"
    end
  end

  should "be mergable" do
    config = Airbrake::Configuration.new
    hash = config.to_hash
    assert_equal hash.merge(:key => 'value'), config.merge(:key => 'value')
  end

  should "allow param filters to be appended" do
    assert_appends_value :params_filters
  end

  should "warn when attempting to read environment filters" do
    config = Airbrake::Configuration.new
    config.
      expects(:warn).
      with(regexp_matches(/deprecated/i))
    assert_equal [], config.environment_filters
  end

  should "warn when attempting to write js_notifier" do
    config = Airbrake::Configuration.new
    config.
      expects(:warn).
      with(regexp_matches(/deprecated/i))
    config.js_notifier = true
  end

  should "allow ignored user agents to be appended" do
    assert_appends_value :ignore_user_agent
  end

  should "allow backtrace filters to be appended" do
    assert_appends_value(:backtrace_filters) do |config|
      new_filter = lambda {}
      config.filter_backtrace(&new_filter)
      new_filter
    end
  end

  should "allow ignore by filters to be appended" do
    assert_appends_value(:ignore_by_filters) do |config|
      new_filter = lambda {}
      config.ignore_by_filter(&new_filter)
      new_filter
    end
  end

  should "allow ignored exceptions to be appended" do
    config = Airbrake::Configuration.new
    original_filters = config.ignore.dup
    new_filter = 'hello'
    config.ignore << new_filter
    assert_same_elements original_filters + [new_filter], config.ignore
  end

  should "allow ignored exceptions to be replaced" do
    assert_replaces(:ignore, :ignore_only=)
  end

  should "allow ignored user agents to be replaced" do
    assert_replaces(:ignore_user_agent, :ignore_user_agent_only=)
  end

  should "use development and test as development environments by default" do
    config = Airbrake::Configuration.new
    assert_same_elements %w(development test cucumber), config.development_environments
  end

  should "be public in a public environment" do
    config = Airbrake::Configuration.new
    config.development_environments = %w(development)
    config.environment_name = 'production'
    assert config.public?
  end

  should "not be public in a development environment" do
    config = Airbrake::Configuration.new
    config.development_environments = %w(staging)
    config.environment_name = 'staging'
    assert !config.public?
  end

  should "be public without an environment name" do
    config = Airbrake::Configuration.new
    assert config.public?
  end

  should "use the assigned logger if set" do
    config = Airbrake::Configuration.new
    config.logger = "CUSTOM LOGGER"
    assert_equal "CUSTOM LOGGER", config.logger
  end

  should 'give a new instance if non defined' do
    Airbrake.configuration = nil
    assert_kind_of Airbrake::Configuration, Airbrake.configuration
  end

  def assert_config_default(option, default_value, config = nil)
    config ||= Airbrake::Configuration.new
    assert_equal default_value, config.send(option)
  end

  def assert_config_overridable(option, value = 'a value')
    config = Airbrake::Configuration.new
    config.send(:"#{option}=", value)
    assert_equal value, config.send(option)
  end

  def assert_appends_value(option, &block)
    config = Airbrake::Configuration.new
    original_values = config.send(option).dup
    block ||= lambda do |config|
      new_value = 'hello'
      config.send(option) << new_value
      new_value
    end
    new_value = block.call(config)
    assert_same_elements original_values + [new_value], config.send(option)
  end

  def assert_replaces(option, setter)
    config = Airbrake::Configuration.new
    new_value = 'hello'
    config.send(setter, [new_value])
    assert_equal [new_value], config.send(option)
    config.send(setter, new_value)
    assert_equal [new_value], config.send(option)
  end

end
