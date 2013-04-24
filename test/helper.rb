require 'test/unit'
require 'rubygems'

$LOAD_PATH << File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))

require 'thread'

require 'mocha'

require 'abstract_controller'
require 'action_controller'
require 'action_dispatch'
require 'active_support/dependencies'
require 'active_model'
require 'active_record'
require 'active_support/core_ext/kernel/reporting'

require 'nokogiri'
require 'rack'
require 'bourne'
require 'sham_rack'
require 'json-schema'

require "airbrake"

require "shoulda-matchers"
require "shoulda-context"

begin require 'redgreen'; rescue LoadError; end

# Show backtraces for deprecated behavior for quicker cleanup.
ActiveSupport::Deprecation.debug = true

FIXTURE_LOAD_PATH = File.join(File.dirname(__FILE__), 'fixtures')
FIXTURES = Pathname.new(FIXTURE_LOAD_PATH)

SharedTestRoutes = ActionDispatch::Routing::RouteSet.new

class RoutedRackApp
  attr_reader :routes

  def initialize(routes, &blk)
    @routes = routes
    @stack = ActionDispatch::MiddlewareStack.new(&blk).build(@routes)
  end

  def call(env)
    @stack.call(env)
  end
end

unless defined?(ActionDispatch::IntegrationTest)
  class ActionController::IntegrationTest < ActiveSupport::TestCase
    def self.build_app(routes = nil)
      RoutedRackApp.new(routes || ActionDispatch::Routing::RouteSet.new) do |middleware|
        yield(middleware) if block_given?
      end
    end

    self.app = build_app

    # Stub Rails dispatcher so it does not get controller references and
    # simply return the controller#action as Rack::Body.
    class StubDispatcher < ::ActionDispatch::Routing::RouteSet::Dispatcher
      protected
      def controller_reference(controller_param)
        controller_param
      end

      def dispatch(controller, action, env)
        [200, {'Content-Type' => 'text/html'}, ["#{controller}##{action}"]]
      end
    end

    def self.stub_controllers
      old_dispatcher = ActionDispatch::Routing::RouteSet::Dispatcher
      ActionDispatch::Routing::RouteSet.module_eval { remove_const :Dispatcher }
      ActionDispatch::Routing::RouteSet.module_eval { const_set :Dispatcher, StubDispatcher }
      yield ActionDispatch::Routing::RouteSet.new
    ensure
      ActionDispatch::Routing::RouteSet.module_eval { remove_const :Dispatcher }
      ActionDispatch::Routing::RouteSet.module_eval { const_set :Dispatcher, old_dispatcher }
    end

    def with_routing(&block)
      temporary_routes = ActionDispatch::Routing::RouteSet.new
      old_app, self.class.app = self.class.app, self.class.build_app(temporary_routes)
      old_routes = SharedTestRoutes
      silence_warnings { Object.const_set(:SharedTestRoutes, temporary_routes) }

      yield temporary_routes
    ensure
      self.class.app = old_app
      silence_warnings { Object.const_set(:SharedTestRoutes, old_routes) }
    end

    def with_autoload_path(path)
      path = File.join(File.dirname(__FILE__), "fixtures", path)
      if ActiveSupport::Dependencies.autoload_paths.include?(path)
        yield
      else
        begin
          ActiveSupport::Dependencies.autoload_paths << path
          yield
        ensure
          ActiveSupport::Dependencies.autoload_paths.reject! {|p| p == path}
          ActiveSupport::Dependencies.clear
        end
      end
    end
  end
end

class ActionDispatch::IntegrationTest < ActiveSupport::TestCase
  setup do
    @routes = SharedTestRoutes
  end
end



module ActionController
  class Base
    include ActionController::Testing
  end

  Base.view_paths = FIXTURE_LOAD_PATH

  class TestCase
    include ActionDispatch::TestProcess

    setup do
      @routes = SharedTestRoutes
    end
  end
end

# This stub emulates the Railtie including the URL helpers from a Rails application
module ActionController
  class Base
    include SharedTestRoutes.url_helpers
  end
end


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

class Test::Unit::TestCase
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

# Also stolen from AS 2.3.2
class Array
  # Wraps the object in an Array unless it's an Array.  Converts the
  # object to an Array using #to_ary if it implements that.
  def self.wrap(object)
    case object
    when nil
      []
    when self
      object
    else
      if object.respond_to?(:to_ary)
        object.to_ary
      else
        [object]
      end
    end
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
