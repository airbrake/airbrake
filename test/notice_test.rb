require File.dirname(__FILE__) + '/helper'

class NoticeTest < Test::Unit::TestCase

  include DefinesConstants

  def configure
    returning HoptoadNotifier::Configuration.new do |config|
      config.api_key = 'abc123def456'
    end
  end

  def build_notice(args = {})
    configuration = args.delete(:configuration) || configure
    HoptoadNotifier::Notice.new(configuration.merge(args))
  end

  def stub_request(attrs = {})
    stub('request', { :parameters  => { 'one' => 'two' },
                      :protocol    => 'http',
                      :host        => 'some.host',
                      :request_uri => '/some/uri',
                      :session     => { :to_hash => { 'a' => 'b' } },
                      :env         => { 'three' => 'four' } }.update(attrs))
  end

  should "set the api key" do
    api_key = 'key'
    notice = build_notice(:api_key => api_key)
    assert_equal api_key, notice.api_key
  end

  should "accept a project root" do
    project_root = '/path/to/project'
    notice = build_notice(:project_root => project_root)
    assert_equal project_root, notice.project_root
  end

  should "accept a url" do
    url = 'http://some.host/uri'
    notice = build_notice(:url => url)
    assert_equal url, notice.url
  end

  should "accept a backtrace from an exception or hash" do
    assert_accepts_exception_attribute :backtrace, :backtrace_filters => []
  end

  should "set the error class from an exception or hash" do
    assert_accepts_exception_attribute :error_class do |exception|
      exception.class.name
    end
  end

  should "set the error message from an exception or hash" do
    assert_accepts_exception_attribute :error_message do |exception|
      "#{exception.class.name}: #{exception.message}"
    end
  end

  should "accept parameters from a request or hash" do
    parameters = { 'one' => 'two' }
    notice_from_hash = build_notice(:parameters => parameters)
    assert_equal notice_from_hash.parameters, parameters
  end

  should "accept session data from a session[:data] hash" do
    data = { 'one' => 'two' }
    notice = build_notice(:session => { :data => data })
    assert_equal data, notice.session_data
  end

  should "accept session data from a session_data hash" do
    data = { 'one' => 'two' }
    notice = build_notice(:session_data => data)
    assert_equal data, notice.session_data
  end

  should "set the environment from a hash or ENV" do
    custom_env = { 'string' => 'value' }
    custom_notice = build_notice(:environment => custom_env)
    assert_equal custom_env, custom_notice.environment, "should take an environment from a hash"

    default_notice = build_notice({})
    assert_equal ENV.to_hash,
                 default_notice.environment,
                 "should set environment to ENV without a hash"
  end

  should "parse massive one-line exceptions into multiple lines" do
    original_backtrace = ["one big line\n   separated\n      by new lines\nand some spaces"]
    expected_backtrace = ["one big line", "separated", "by new lines", "and some spaces"]

    notice = build_notice(:backtrace => original_backtrace, :backtrace_filters => [])

    assert_equal expected_backtrace, notice.backtrace
  end

  should "set sensible defaults without an exception" do
    backtrace = caller
    notice = build_notice(:backtrace_filters => [])

    assert_equal 'Notification', notice.error_message
    assert_equal ENV.to_hash, notice.environment
    assert_array_starts_with backtrace, notice.backtrace
    assert_equal({}, notice.parameters)
    assert_equal({}, notice.session_data)
  end

  should "convert unserializable objects to strings" do
    assert_serializes_hash(:environment)
    assert_serializes_hash(:parameters)
  end

  should "remove notifier trace" do
    inside_notifier  = ['lib/hoptoad_notifier.rb:13:in `voodoo`']
    outside_notifier = ['users_controller:8:in `index`']
    backtrace        = inside_notifier + outside_notifier
    notice           = build_notice(:backtrace => backtrace)

    assert_equal outside_notifier, notice.backtrace
  end

  should "filter the backtrace" do
    filters = [lambda { |line| line = "1234" }]
    backtrace = %w(foo bar)
    notice = build_notice(:backtrace_filters => filters, :backtrace => backtrace)

    assert_equal %w(1234 1234), notice.backtrace
  end

  should "filter parameters" do
    filters = %w(abc def)
    params  = { 'abc' => "123", 'def' => "456", 'ghi' => "789" }

    notice = build_notice(:params_filters => filters, :parameters => params)

    assert_equal({ 'abc' => "[FILTERED]", 'def' => "[FILTERED]", 'ghi' => "789" },
                 notice.parameters)
  end

  should "filter environment data" do
    filters = %w(secret supersecret)
    env     = { :secret      => "123",
                :supersecret => "456",
                :ghi         => "789" }
    notice = build_notice(:environment => env, :environment_filters => filters)

    assert_equal({ :secret => "[FILTERED]", :supersecret => "[FILTERED]", :ghi => "789" },
                 notice.environment)
  end

  should "generate yaml" do
    input = {
      :backtrace_filters => [],
      :api_key           => 'abcdefghi123',
      :error_class       => 'ArgumentError',
      :error_message     => 'No arguing',
      :project_root      => '/path/to/project',
      :url               => 'http://some.host/users/4',
      :backtrace         => caller,
      :environment       => { 'one' => 'two' },
      :parameters        => { 'controller' => 'users',
                              'action'     => 'show',
                              'id'         => '4' },
      :session           => { 'user_id' => '3' }
    }

    notice = build_notice(input)
    yaml = notice.to_yaml
    actual = YAML.load(yaml)

    expected = {
      'api_key'       => input[:api_key],
      'error_class'   => input[:error_class],
      'error_message' => "#{input[:error_class]}: #{input[:error_message]}",
      'backtrace'     => input[:backtrace],
      'environment'   => input[:environment],
      'request'       => { 'rails_root' => input[:project_root],
                           'url'        => input[:url],
                           'params'     => input[:parameters] },
      'session'       => { 'data' => input[:session] }
    }


    assert_equal expected, actual['notice']
  end

  should "not ignore an exception not matching ignore filters" do
    notice = build_notice(:error_class       => 'ArgumentError',
                          :ignore            => ['Argument'],
                          :ignore_by_filters => [lambda { false }])
    assert !notice.ignore?
  end

  should "ignore an exception with a matching error class" do
    notice = build_notice(:error_class => 'ArgumentError',
                          :ignore      => [ArgumentError])
    assert notice.ignore?
  end

  should "ignore an exception with a matching error class name" do
    notice = build_notice(:error_class => 'ArgumentError',
                          :ignore      => ['ArgumentError'])
    assert notice.ignore?
  end

  should "ignore an exception with a matching filter" do
    filter = lambda {|notice| notice.error_class == 'ArgumentError' }
    notice = build_notice(:error_class       => 'ArgumentError',
                          :ignore_by_filters => [filter])
    assert notice.ignore?
  end

  should "not raise without an ignore list" do
    notice = build_notice(:ignore => nil, :ignore_by_filters => nil)
    assert_nothing_raised do
      notice.ignore?
    end
  end

  should "not raise when filtering without a RAILS_ROOT" do
    assert !defined?(RAILS_ROOT)
    assert_nothing_raised { build_notice }
  end

  should "filter out the RAILS_ROOT if there is one" do
    project_root = '/some/path'
    backtrace_with_root = ["#{project_root}/app/models/user.rb:7:in `latest'",
                           "#{project_root}/app/controllers/users_controller.rb:13:in `index'",
                           "/lib/something.rb:41:in `open'"]
    backtrace_without_root = ["[RAILS_ROOT]/app/models/user.rb:7:in `latest'",
                              "[RAILS_ROOT]/app/controllers/users_controller.rb:13:in `index'",
                              "/lib/something.rb:41:in `open'"]
    define_constant('RAILS_ROOT', project_root)

    notice = build_notice(:backtrace => backtrace_with_root)

    assert_equal backtrace_without_root, notice.backtrace
  end

  should "act like a hash" do
    notice = build_notice(:error_message => 'some message')
    assert_equal notice.error_message, notice[:error_message]
  end

  should "return params on notice[:request][:params]" do
    params = { 'one' => 'two' }
    notice = build_notice(:parameters => params)
    assert_equal params, notice[:request][:params]
  end

  def assert_array_starts_with(expected, actual)
    assert_respond_to actual, :to_ary
    array = actual.to_ary.reverse
    expected.reverse.each_with_index do |value, i|
      assert_equal value, array[i]
    end
  end

  def assert_accepts_exception_attribute(attribute, args = {}, &block)
    exception = build_exception
    block ||= lambda { exception.send(attribute) }
    value = block.call(exception)

    notice_from_exception = build_notice(args.merge(:exception => exception))
    assert_equal notice_from_exception.send(attribute),
                 value,
                 "#{attribute} was not correctly set from an exception"

    notice_from_hash = build_notice(args.merge(attribute => value))
    assert_equal notice_from_hash.send(attribute),
                 value,
                 "#{attribute} was not correctly set from a hash"
  end

  def assert_serializes_hash(attribute)
    [File.open(__FILE__), Proc.new { puts "boo!" }, Module.new].each do |object|
      hash = {
        :strange_object => object,
        :sub_hash => {
          :sub_object => object
        },
        :array => [object]
      }
      notice = build_notice(attribute => hash)
      hash = notice.send(attribute)
      assert_equal object.to_s, hash[:strange_object], "objects should be serialized"
      assert_kind_of Hash, hash[:sub_hash], "subhashes should be kept"
      assert_equal object.to_s, hash[:sub_hash][:sub_object], "subhash members should be serialized"
      assert_kind_of Array, hash[:array], "arrays should be kept"
      assert_equal object.to_s, hash[:array].first, "array members should be serialized"
    end
  end

end
