require 'airbrake/rails/controller_methods'
require 'airbrake/rails/middleware'

unless defined?(ActionDispatch::IntegrationTest) # Rails 3.0
  # what follows is a dirty hack which makes
  # AD::IntegrationTest possible in Rails 3.0
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
end # end Rails 3.0 hack

module ActionDispatch
  class ShowExceptions
    private
    def public_path
      "/null"
    end

    # Silence logger
    def logger
      Logger.new("/dev/null")
    end
  end
end

class ActionControllerCatcherTest < ActionDispatch::IntegrationTest

  include DefinesConstants
  include TestHelpers

  def setup
    super
    reset_config
    Airbrake.sender = CollectingSender.new
    Airbrake.configuration.development_environments = []
    define_constant('RAILS_ROOT', '/path/to/rails/root')
  end

  def ignore(exception_class)
    Airbrake.configuration.ignore << exception_class
  end

  def assert_sent_hash(hash, xpath)
    hash.each do |key, value|
      next if key.match(/^airbrake\./) || # We added this key.
        hash[key] !~ /\S/

        element_xpath = "#{xpath}/var[@key = '#{key}']"
      if value.respond_to?(:to_hash)
        assert_sent_hash value.to_hash, element_xpath
      else
        next if key == "action_dispatch.exception" # TODO: Rails 3.2 only - review
        value.gsub!(/\d/,"") if key == "PATH_INFO" # TODO: Rails 3.2 only - review
        assert_sent_element value, element_xpath
      end
    end
  end

  def assert_sent_element(value, xpath)
    assert_valid_node last_sent_notice_document, xpath, stringify_array_elements(value).to_s
  end

  def stringify_array_elements(data)
    if data.respond_to?(:to_ary)
      data.collect do |value|
        stringify_array_elements(value)
      end
    else
      data.to_s
    end
  end

  def assert_sent_request_info_for(request)
    params = request.parameters.to_hash
    assert_sent_hash params, '/notice/request/params'
    assert_sent_element params['controller'], '/notice/request/component'
    assert_sent_element params['action'], '/notice/request/action'
    assert_sent_element url_from_request(request), '/notice/request/url'
    assert_sent_hash request.env, '/notice/request/cgi-data'
  end

  def url_from_request(request)
    url = "#{request.protocol}#{request.host}"

    unless [80, 443].include?(request.port)
      url << ":#{request.port}"
    end

    url << request.fullpath.gsub(%r{\d},"") # TODO: Rails 3.2 only - review

    url
  end

  def sender
    Airbrake.sender
  end

  def last_sent_notice_xml
    sender.collected.last.to_xml
  end

  def last_sent_notice_document
    assert_not_nil xml = last_sent_notice_xml, "No xml was sent"
    Nokogiri::XML.parse(xml)
  end

  class AirbrakeTestController < ActionController::Base
    begin
      use ActionDispatch::ShowExceptions, ActionDispatch::PublicExceptions.new("/null")
    rescue NameError
      use ActionDispatch::ShowExceptions
    end

    use Airbrake::Rails::Middleware

    include Airbrake::Rails::ControllerMethods

    cattr_accessor :local

    before_filter :set_session

    def set_session
      unless params.empty?
        request.session = ActionController::TestSession.new(params[:session] || {})
      end
    end

    def boom
      raise "boom"
      render :nothing => true
    end

    def hello
      render :text => "hello"
    end

    def manual_airbrake
      notify_airbrake(:error_message => "fail")
      render :nothing => true
    end

    protected

    def airbrake_local_request?
      @@local
    end
  end

  setup do
    Airbrake.configuration.development_environments = []
  end


  def test_deliver_notices_from_exceptions_raised_in_public_requests
    @app = AirbrakeTestController.action(:boom)
    get '/'
    assert_caught_and_sent
  end

  def test_not_deliver_notices_from_exceptions_in_development_environments
    Airbrake.configuration.development_environments = ["test"]
    Airbrake.configuration.environment_name = "test"
    @app = AirbrakeTestController.action(:boom)
    get '/'
    assert_caught_and_not_sent
  end

  def test_not_deliver_notices_from_exceptions_with_no_api_key
    Airbrake.configuration.api_key = nil
    @app = AirbrakeTestController.action(:boom)
    get '/'
    assert_caught_and_not_sent
  end

  def test_not_deliver_notices_from_actions_that_dont_raise
    @app = AirbrakeTestController.action(:hello)
    get '/'
    assert_caught_and_not_sent
    assert_equal 'hello', response.body
  end

  def test_not_deliver_ignored_exceptions_raised_by_actions
    @app = AirbrakeTestController.action(:boom)
    ignore(RuntimeError)
    get '/'
    assert_caught_and_not_sent
  end

  def test_deliver_ignored_exception_raised_manually
    @app = AirbrakeTestController.action(:manual_airbrake)
    ignore(RuntimeError)
    get '/'
    assert_caught_and_sent
  end

  def test_not_deliver_manually_sent_notices_in_local_requests
    AirbrakeTestController.local = true
    @app = AirbrakeTestController.action(:manual_airbrake)
    get '/'
    assert_caught_and_not_sent
    AirbrakeTestController.local = false
  end

  def test_not_create_actions_from_airbrake_methods
    Airbrake::Rails::ControllerMethods.instance_methods.each do |method|
      assert !(AirbrakeTestController.new.action_methods.include?(method))
    end
  end

  def test_ignore_exceptions_when_user_agent_is_being_ignored_by_regular_expression
    Airbrake.configuration.ignore_user_agent_only = [/Ignored/]
    @app = AirbrakeTestController.action(:boom)
    get "/", {}, {"HTTP_USER_AGENT" => "ShouldBeIgnored"}
    assert_caught_and_not_sent
  end

  def test_ignore_exceptions_when_user_agent_is_being_ignored_by_string
    Airbrake.configuration.ignore_user_agent_only = ['IgnoredUserAgent']
    @app = AirbrakeTestController.action(:boom)
    get "/", {}, {"HTTP_USER_AGENT" => "IgnoredUserAgent"}
    assert_caught_and_not_sent
  end

  def test_not_ignore_exceptions_when_user_agent_is_not_being_ignored
    Airbrake.configuration.ignore_user_agent_only = ['IgnoredUserAgent']
    @app = AirbrakeTestController.action(:boom)
    get "/", {}, {"HTTP_USER_AGENT" => "NonIgnoredAgent"}
    assert_caught_and_sent
  end

  def test_send_session_data_for_manual_notifications
    @app = AirbrakeTestController.action(:manual_airbrake)
    data = { 'one' => 'two' }
    get "/", :session => data
    assert_sent_hash data, "/notice/request/session"
  end

  def test_send_request_data_for_manual_notification
    params = { 'controller' => "airbrake_test", 'action' => "index" }
    @app = AirbrakeTestController.action(:manual_airbrake)
    get "/", params
    assert_sent_request_info_for @request
  end

  def test_send_request_data_for_manual_notification_with_non_standard_port
    params = { 'controller' => "airbrake_test", 'action' => "index" }
    @app = AirbrakeTestController.action(:manual_airbrake)
    get "/", params, {"SERVER_PORT" => 81}
    assert_sent_request_info_for @request
  end

  def test_send_request_data_for_automatic_notification
    params = { 'controller' => "airbrake_test", 'action' => "index" }
    @app = AirbrakeTestController.action(:boom)
    get "/", params
    assert_sent_request_info_for @request
  end

  def test_send_request_data_for_automatic_notification_with_non_standard_port
    params = { 'controller' => "airbrake_test", 'action' => "index" }
    @app = AirbrakeTestController.action(:boom)
    get "/", params, {"SERVER_PORT" => 81}
    assert_sent_request_info_for @request
    assert_sent_element 81, "/notice/request/cgi-data/var[@key = 'SERVER_PORT']"
  end
end
