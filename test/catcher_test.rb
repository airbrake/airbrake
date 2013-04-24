require File.expand_path '../helper', __FILE__

require 'airbrake/rails/controller_methods'
require 'airbrake/rails/middleware'

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
        hash[key].blank?

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


  def deliver_notices_from_exceptions_raised_in_public_requests
    @app = AirbrakeTestController.action(:boom)
    get '/'
    assert_caught_and_sent
  end

  def not_deliver_notices_from_exceptions_in_development_environments
    Airbrake.configuration.development_environments = ["test"]
    Airbrake.configuration.environment_name = "test"
    @app = AirbrakeTestController.action(:boom)
    get '/'
    assert_caught_and_not_sent
  end

  def not_deliver_notices_from_actions_that_dont_raise
    @app = AirbrakeTestController.action(:hello)
    get '/'
    assert_caught_and_not_sent
    assert_equal 'hello', response.body
  end

  def not_deliver_ignored_exceptions_raised_by_actions
    @app = AirbrakeTestController.action(:boom)
    ignore(RuntimeError)
    get '/'
    assert_caught_and_not_sent
  end

  def deliver_ignored_exception_raised_manually
    @app = AirbrakeTestController.action(:manual_airbrake)
    ignore(RuntimeError)
    get '/'
    assert_caught_and_sent
  end

  def not_deliver_manually_sent_notices_in_local_requests
    AirbrakeTestController.local = true
    @app = AirbrakeTestController.action(:manual_airbrake)
    get '/'
    assert_caught_and_not_sent
    AirbrakeTestController.local = false
  end

  def not_create_actions_from_airbrake_methods
    Airbrake::Rails::ControllerMethods.instance_methods.each do |method|
      assert !(AirbrakeTestController.new.action_methods.include?(method))
    end
  end

  def ignore_exceptions_when_user_agent_is_being_ignored_by_regular_expression
    Airbrake.configuration.ignore_user_agent_only = [/Ignored/]
    @app = AirbrakeTestController.action(:boom)
    get "/", {}, {"HTTP_USER_AGENT" => "ShouldBeIgnored"}
    assert_caught_and_not_sent
  end

  def ignore_exceptions_when_user_agent_is_being_ignored_by_string
    Airbrake.configuration.ignore_user_agent_only = ['IgnoredUserAgent']
    @app = AirbrakeTestController.action(:boom)
    get "/", {}, {"HTTP_USER_AGENT" => "IgnoredUserAgent"}
    assert_caught_and_not_sent
  end

  def not_ignore_exceptions_when_user_agent_is_not_being_ignored
    Airbrake.configuration.ignore_user_agent_only = ['IgnoredUserAgent']
    @app = AirbrakeTestController.action(:boom)
    get "/", {}, {"HTTP_USER_AGENT" => "NonIgnoredAgent"}
    assert_caught_and_sent
  end

  def send_session_data_for_manual_notifications
    @app = AirbrakeTestController.action(:manual_airbrake)
    data = { 'one' => 'two' }
    get "/", :session => data
    assert_sent_hash data, "/notice/request/session"
  end

  def send_request_data_for_manual_notification
    params = { 'controller' => "airbrake_test", 'action' => "index" }
    @app = AirbrakeTestController.action(:manual_airbrake)
    get "/", params
    assert_sent_request_info_for @request
  end

  def send_request_data_for_manual_notification_with_non_standard_port
    params = { 'controller' => "airbrake_test", 'action' => "index" }
    @app = AirbrakeTestController.action(:manual_airbrake)
    get "/", params, {"SERVER_PORT" => 81}
    assert_sent_request_info_for @request
  end

  def send_request_data_for_automatic_notification
    params = { 'controller' => "airbrake_test", 'action' => "index" }
    @app = AirbrakeTestController.action(:boom)
    get "/", params
    assert_sent_request_info_for @request
  end

  def send_request_data_for_automatic_notification_with_non_standard_port
    params = { 'controller' => "airbrake_test", 'action' => "index" }
    @app = AirbrakeTestController.action(:boom)
    get "/", params, {"SERVER_PORT" => 81}
    assert_sent_request_info_for @request
    assert_sent_element 81, "/notice/request/cgi-data/var[@key = 'SERVER_PORT']"
  end
end
