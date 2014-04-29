require "simplecov" 

if ENV["INTEGRATION"] then SimpleCov.command_name "test:integration"
else SimpleCov.command_name "test:units"
end

SimpleCov.merge_timeout 3600 
SimpleCov.start

if ENV["CI"]
  require "coveralls"
  Coveralls.wear_merged!
end

$VERBOSE = ENV["VERBOSE"]

module Kernel
  def silence_warnings
    with_warnings(nil) { yield }
  end

  def with_warnings(flag)
    old_verbose, $VERBOSE = $VERBOSE, flag
    yield
  ensure
    $VERBOSE = old_verbose
  end
end

silence_warnings do
  require 'test/unit'
  require 'rubygems'

  require 'thread'

  require 'mocha/setup'
  require 'nokogiri'
  require 'rack'
  require 'bourne'
  require 'sham_rack'
  require 'json-schema'
  require "shoulda-matchers"
  require "shoulda-context"
  require "fakeweb"
  require "pry"

  begin require 'redgreen'; rescue LoadError; end
end

$LOAD_PATH << File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))

require "airbrake"

XSD_SCHEMA_PATH    = "http://airbrake.io/airbrake_#{Airbrake::API_VERSION.tr(".","_")}.xsd"
COVERALLS_API_URL  = "https://coveralls.io/api/v1"

FakeWeb.allow_net_connect = %r{#{XSD_SCHEMA_PATH}|#{COVERALLS_API_URL}}

module TestMethods
  def rescue_action e
    raise e
  end

  def do_raise
    raise "Airbrake"
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
    notify_airbrake(Exception.new)
    render :text => "Success"
  end

  def manual_notify_ignored
    notify_airbrake(ActiveRecord::RecordNotFound.new("404"))
    render :text => "Success"
  end
end

module TestHelpers
  def stub_sender
    stub('sender', :send_to_airbrake => nil)
  end

  def stub_sender!
    Airbrake.sender = stub_sender
  end

  def stub_notice
    stub('notice', :to_xml => 'some yaml', :ignore? => false)
  end

  def stub_notice!
     stub_notice.tap do |notice|
      Airbrake::Notice.stubs(:new => notice)
    end
  end

  def reset_config
    Airbrake.configuration = nil
    Airbrake.configure do |config|
      config.api_key = 'abc123'
    end
  end

  def clear_backtrace_filters
    Airbrake.configuration.backtrace_filters.clear
  end

  def build_exception(opts = {})
    backtrace = ["airbrake/test/helper.rb:132:in `build_exception'",
                 "airbrake/test/backtrace.rb:4:in `build_notice_data'",
                 "/var/lib/gems/1.8/gems/airbrake-2.4.5/rails/init.rb:2:in `send_exception'"]
    opts = {:backtrace => backtrace}.merge(opts)
    BacktracedException.new(opts)
  end

  def build_notice_data(exception = nil)
    exception ||= build_exception
    {
      :api_key       => 'abc123',
      :error_class   => exception.class.name,
      :error_message => "#{exception.class.name}: #{exception.message}",
      :backtrace     => exception.backtrace,
      :environment   => { 'PATH' => '/bin', 'REQUEST_URI' => '/users/1' },
      :request       => {
        :params     => { 'controller' => 'users', 'action' => 'show', 'id' => '1' },
        :rails_root => '/path/to/application',
        :url        => "http://test.host/users/1"
      },
      :session       => {
        :key  => '123abc',
        :data => { 'user_id' => '5', 'flash' => { 'notice' => 'Logged in successfully' } }
      }
    }
  end

  def assert_caught_and_sent
    assert !Airbrake.sender.collected.empty?
  end

  def assert_caught_and_not_sent
    assert Airbrake.sender.collected.empty?
  end

  def assert_array_starts_with(expected, actual)
    assert_respond_to actual, :to_ary
    array = actual.to_ary.reverse
    expected.reverse.each_with_index do |value, i|
      assert_equal value, array[i]
    end
  end

  def assert_valid_node(document, xpath, content)
    nodes = document.xpath(xpath)
    assert nodes.any?{|node| node.content == content },
           "Expected xpath #{xpath} to have content #{content}, " +
           "but found #{nodes.map { |n| n.content }} in #{nodes.size} matching nodes." +
           "Document:\n#{document.to_s}"
  end

  def assert_logged(expected)
    assert_received(Airbrake, :write_verbose_log) do |expect|
      expect.with {|actual| actual =~ expected }
    end
  end

  def assert_not_logged(expected)
    assert_received(Airbrake, :write_verbose_log) do |expect|
      expect.with {|actual| actual =~ expected }.never
    end
  end
end

class Test::Unit::TestCase
  include ::TestHelpers
end

module DefinesConstants
  def setup
    @defined_constants = []
  end

  def teardown
    @defined_constants.each do |constant|
      Object.__send__(:remove_const, constant)
    end
  end

  def define_constant(name, value)
    Object.const_set(name, value)
    @defined_constants << name
  end
end

class CollectingSender
  attr_reader :collected

  def initialize
    @collected = []
  end

  def send_to_airbrake(data)
    @collected << data
  end
end

class BacktracedException < Exception
  attr_accessor :backtrace

  def initialize(opts)
    @backtrace = opts[:backtrace]
  end

  def set_backtrace(bt)
    @backtrace = bt
  end

  def message
    "Something went wrong. Did you press the red button?"
  end
end
