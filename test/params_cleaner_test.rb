require File.expand_path '../helper', __FILE__

class ParamsCleanerTest < Test::Unit::TestCase

  def clean(opts = {})
    cleaner = Airbrake::Utils::ParamsCleaner.new(:blacklist_filters  => opts.delete(:params_filters) || [],
                                                 :whitelist_filters  => opts.delete(:whitelist_params_filters) || [],
                                                 :rack_vars_filters  => opts.delete(:rack_vars_filters) || [],
                                                 :to_clean => opts)
    cleaner.clean
  end

  def assert_serializes_hash(attribute)
    [File.open(__FILE__), Proc.new { puts "boo!" }, Module.new, nil].each do |object|
      hash = {
        :strange_object => object,
        :sub_hash => {
          :sub_object => object
        },
        :array => [object]
      }
      clean_params = clean(attribute => hash)
      hash = clean_params.send(attribute)
      object_serialized = object.nil? ? nil : object.to_s
      assert_equal object_serialized, hash[:strange_object], "objects should be serialized"
      assert_kind_of Hash, hash[:sub_hash], "subhashes should be kept"
      assert_equal object_serialized, hash[:sub_hash][:sub_object], "subhash members should be serialized"
      assert_kind_of Array, hash[:array], "arrays should be kept"
      assert_equal object_serialized, hash[:array].first, "array members should be serialized"
    end
  end

  def sensitive_rack_vars
    {
      "HTTP_X_CSRF_TOKEN" => "remove_me",
      "HTTP_COOKIE" => "remove_me",
      "HTTP_AUTHORIZATION" => "remove_me",
      "action_dispatch.request.unsigned_session_cookie" => "remove_me",
      "action_dispatch.cookies" => "remove_me",
      "action_dispatch.unsigned_session_cookie" => "remove_me",
      "action_dispatch.secret_key_base" => "remove_me",
      "action_dispatch.signed_cookie_salt" => "remove_me",
      "action_dispatch.encrypted_cookie_salt" => "remove_me",
      "action_dispatch.encrypted_signed_cookie_salt" => "remove_me",
      "action_dispatch.http_auth_salt" => "remove_me",
      "action_dispatch.secret_token" => "remove_me",
      "rack.request.cookie_hash" => "remove_me",
      "rack.request.cookie_string" => "remove_me",
      "rack.request.form_vars" => "remove_me",
      "rack.session" => "remove_me",
      "rack.session.options" => "remove_me",
      "rack.request.form_vars" => "story%5Btitle%5D=The+TODO+label",
      "abc" => "123"
    }
  end

  def assert_filters_hash(attribute)
    filters  = ['abc', :def]
    original = {
      'abc' => '123',
      'def' => '456',
      'ghi' => '789',
      'something_with_abc' => 'match the entire string',
      'nested_hash' => { 'abc' => '100', 'ghi' => '789' },
      'nested_array' => [{ 'abc' => '100' }, { 'ghi' => '789' }, 'xyz']
    }
    filtered = {
      'abc' => '[FILTERED]',
      'def' => '[FILTERED]',
      'ghi' => '789',
      'something_with_abc' => 'match the entire string',
      'nested_hash' => { 'abc' => '[FILTERED]', 'ghi' => '789' },
      'nested_array' => [{ 'abc' => '[FILTERED]' }, { 'ghi' => '789' }, 'xyz']
    }

    clean_params = clean(:params_filters => filters, attribute => original)

    assert_equal(filtered, clean_params.send(attribute))
  end

  should "should remove a Rails application's secret token by default" do
    rack_vars_filters = Airbrake::Configuration::DEFAULT_RACK_VARS_FILTERS
    original = {
      "action_dispatch.secret_token" => "abc123xyz456",
      "abc" => "123"
    }
    clean_params = clean(:cgi_data => original,
                         :rack_vars_filters => rack_vars_filters)
    assert_equal({"abc" => "123"}, clean_params.cgi_data)
  end

  should "remove sensitive rack vars by default" do
    rack_vars_filters = Airbrake::Configuration::DEFAULT_RACK_VARS_FILTERS
    clean_params = clean(:cgi_data => sensitive_rack_vars,
                         :rack_vars_filters => rack_vars_filters)
    assert_equal({"abc" => "123"}, clean_params.cgi_data)
  end

  should "not remove sensitive rack vars if rack vars filters empty" do
    clean_params = clean(:cgi_data => sensitive_rack_vars)
    assert_equal(sensitive_rack_vars, clean_params.cgi_data)
  end

  should "respect configuration for rack vars filters" do
    rack_vars_filters = [:foo, /bar/, 'remove_me']
    original = {
      'foo' => 'foo',
      'good_bar' => 'bar',
      'remove_me' => "remove",
      "keep_me" => "keep"
    }
    clean_params = clean(:cgi_data => original,
                         :rack_vars_filters => rack_vars_filters)
    assert_equal({"keep_me" => "keep"}, clean_params.cgi_data)
  end

  should "remove secrets from cgi_data by default" do
    rack_vars_filters = Airbrake::Configuration::DEFAULT_RACK_VARS_FILTERS
    original = {
      "aws_secret_key"   => "secret",
      "service_password" => "password",
      "abc" => "123"
    }

    clean_params = clean(:cgi_data => original,
                         :rack_vars_filters => rack_vars_filters)
    assert_equal({"abc" => "123"}, clean_params.cgi_data)
  end

  should "handle frozen objects" do
    params = {
      'filter_me' => ['a', 'b', 'c', 'd'].freeze
    }

    clean_params = clean({:params_filters => ['filter_me'], :parameters => params})
    assert_equal({'filter_me' => '[FILTERED]'}, clean_params.parameters)
  end

  should "filter parameters" do
    assert_filters_hash(:parameters)
  end

  should "whitelist filter parameters" do
    whitelist_filters  = ["abc", :def]
    original = { 'abc' => "123", 'def' => "456", 'ghi' => "789", 'nested' => { 'abc' => '100' },
      'something_with_abc' => 'match the entire string'}
    filtered = { 'abc'    => "123",
      'def'    => "456",
      'something_with_abc' => "[FILTERED]",
      'ghi'    => "[FILTERED]",
      'nested' => "[FILTERED]" }

    clean_params = clean(:whitelist_params_filters => whitelist_filters,
                         :parameters => original)

    assert_equal(filtered,
                 clean_params.send(:parameters))
  end

  should "not filter everything if whitelist filters are empty" do
    whitelist_filters  = []
    original = { 'abc' => '123' }
    clean_params = clean(:whitelist_params_filters => whitelist_filters,
                         :parameters => original)
    assert_equal(original, clean_params.send(:parameters))
  end

  should "not care if filters are defined in nested array" do
    filters  = [[/crazy/, :foo, ["bar", ["too"]]]]
    original = {
      'this_is_crazy' => 'yes_it_is',
      'I_am_good' => 'yes_you_are',
      'foo' => '1212',
      'too' => '2121',
      'bar' => 'secret'
    }
    filtered = {
      'this_is_crazy' => '[FILTERED]',
      'I_am_good' => 'yes_you_are',
      'foo' => '[FILTERED]',
      'too' => '[FILTERED]',
      'bar' => '[FILTERED]'
    }
    clean_params = clean(:params_filters => filters,
                         :parameters => original)
    assert_equal(filtered, clean_params.send(:parameters))
  end

  should "filter key if it is defined as blacklist and whitelist" do
    original = { 'filter_me' => 'secret' }
    filtered = { 'filter_me' => '[FILTERED]' }
    clean_params = clean(:params_filters => [:filter_me],
                         :params_whitelist_filters => [:filter_me],
                         :parameters => original)
    assert_equal(filtered, clean_params.send(:parameters))
  end

  should "filter cgi data" do
    assert_filters_hash(:cgi_data)
  end

  should "filter session" do
    assert_filters_hash(:session_data)
  end

  should "convert unserializable objects to strings" do
    assert_serializes_hash(:parameters)
    assert_serializes_hash(:cgi_data)
    assert_serializes_hash(:session_data)
  end
end
