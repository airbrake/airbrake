require File.expand_path '../helper', __FILE__

class ParamsCleanerTest < Test::Unit::TestCase

  def clean(opts = {})
    cleaner = Airbrake::Utils::ParamsCleaner.new(:filters  => opts.delete(:params_filters),
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

  def assert_filters_hash(attribute)
    filters  = ["abc", :def]
    original = { 'abc' => "123", 'def' => "456", 'ghi' => "789", 'nested' => { 'abc' => '100' },
      'something_with_abc' => 'match the entire string'}
    filtered = { 'abc'    => "[FILTERED]",
      'def'    => "[FILTERED]",
      'something_with_abc' => "match the entire string",
      'ghi'    => "789",
      'nested' => { 'abc' => '[FILTERED]' } }

    clean_params = clean(:params_filters => filters,
                    attribute => original)

    assert_equal(filtered,
                 clean_params.send(attribute))
  end

  should "should always remove a Rails application's secret token" do
    original = {
      "action_dispatch.secret_token" => "abc123xyz456",
      "abc" => "123"
    }
    clean_params = clean(:cgi_data => original)
    assert_equal({"abc" => "123"}, clean_params.cgi_data)
  end

  should "remove rack.request.form_vars" do
    original = {
      "rack.request.form_vars" => "story%5Btitle%5D=The+TODO+label",
      "abc" => "123"
    }

    clean_params = clean(:cgi_data => original)
    assert_equal({"abc" => "123"}, clean_params.cgi_data)
  end

  should "remove secrets from cgi_data" do
    original = {
      "aws_secret_key"   => "secret",
      "service_password" => "password",
      "abc" => "123"
    }

    clean_params = clean(:cgi_data => original)
    assert_equal({"abc" => "123"}, clean_params.cgi_data)
  end

  should "filter parameters" do
    assert_filters_hash(:parameters)
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
