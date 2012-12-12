require File.expand_path '../helper', __FILE__

require 'airbrake/rails/controller_methods'
require 'airbrake/rails/middleware/exceptions_catcher'

module ActionDispatch
  class ShowExceptions
    include Airbrake::Rails::Middleware::ExceptionsCatcher
    private
    def public_path
      "/null"
    end

    # Silence logger
    def logger
      nil
    end
  end
end

class ActionControllerCatcherTest < ActionDispatch::IntegrationTest

  include DefinesConstants

  def setup
    super
    reset_config
    Airbrake.configuration.environment_name = "test"
    Airbrake.sender = CollectingSender.new
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

    url << request.fullpath

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

    include Airbrake::Rails::ControllerMethods

    cattr_accessor :local

    before_filter :params_magic

    def params_magic
      unless params.empty?

        if params[:user_agent]
          if request.respond_to?(:user_agent=)
            request.user_agent = params[:user_agent]
          else
            request.env["HTTP_USER_AGENT"] = params[:user_agent]
          end
        end

        request.session = ActionController::TestSession.new(params[:session] || {})
        request.port = params[:port] if params[:port]
      end
    end

    def boom
      raise "boom"
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


   should "deliver notices from exceptions raised in public requests" do
     Airbrake.configuration.environment_name = "production"

     @app = AirbrakeTestController.action(:boom)
     get '/'
     assert_caught_and_sent
   end

  should "not deliver notices from exceptions in development environments" do
     @app = AirbrakeTestController.action(:boom)
     get '/'
     assert_caught_and_not_sent
  end

   should "not deliver notices from actions that don't raise" do
     @app = AirbrakeTestController.action(:hello)
     get '/'
     assert_caught_and_not_sent
     assert_equal 'hello', response.body
   end

   should "not deliver ignored exceptions raised by actions" do
     @app = AirbrakeTestController.action(:boom)
     ignore(RuntimeError)
     get '/'
     assert_caught_and_not_sent
   end

   should "deliver ignored exception raised manually" do
     Airbrake.configuration.environment_name = "production"
     @app = AirbrakeTestController.action(:manual_airbrake)
     ignore(RuntimeError)
     get '/'
     assert_caught_and_sent
   end

   should "not deliver manually sent notices in local requests" do
     Airbrake.configuration.environment_name = "production"
     AirbrakeTestController.local = true
     @app = AirbrakeTestController.action(:manual_airbrake)
     get '/'
     assert_caught_and_not_sent
     AirbrakeTestController.local = false
   end


   # TODO: remove this since it should be tested in integration tests
   # should "continue with default behavior after delivering an exception" do
   #    Airbrake.configuration.environment_name = "production"
   #    @app = AirbrakeTestController.action(:boom)
   #    get '/'
   #    assert_received(ActionDispatch::ShowExceptions, :render_exception)
   # end

   should "not create actions from Airbrake methods" do
     Airbrake::Rails::ControllerMethods.instance_methods.each do |method|
       assert !(AirbrakeTestController.new.action_methods.include?(method))
     end
   end

   should "ignore exceptions when user agent is being ignored by regular expression" do
     Airbrake.configuration.ignore_user_agent_only = [/Ignored/]
     @app = AirbrakeTestController.action(:boom)
     get "/", :user_agent => "ShouldBeIgnored"
     assert_caught_and_not_sent
   end

   should "ignore exceptions when user agent is being ignored by string" do
     Airbrake.configuration.ignore_user_agent_only = ['IgnoredUserAgent']
     @app = AirbrakeTestController.action(:boom)
     get "/", :user_agent => "ShouldBeIgnored"
     assert_caught_and_not_sent
   end

   should "not ignore exceptions when user agent is not being ignored" do
     Airbrake.configuration.ignore_user_agent_only = ['IgnoredUserAgent']
     @app = AirbrakeTestController.action(:boom)
     get "/", :user_agent => "NonIgnoredAgent"
     assert_caught_and_not_sent
   end

   should "send session data for manual notifications" do
     Airbrake.configuration.environment_name = "production"
     @app = AirbrakeTestController.action(:manual_airbrake)
     data = { 'one' => 'two' }
     get "/", :session => data
     assert_sent_hash data, "/notice/request/session"
   end

   should "send request data for manual notification" do
     Airbrake.configuration.environment_name = "production"
     params = { 'controller' => "airbrake_test", 'action' => "index" }
     @app = AirbrakeTestController.action(:manual_airbrake)
     get "/", params
     assert_sent_request_info_for @request
   end

   should "send request data for manual notification with non-standard port" do
     Airbrake.configuration.environment_name = "production"
     params = { 'controller' => "airbrake_test", 'action' => "index" }
     @app = AirbrakeTestController.action(:manual_airbrake)
     get "/", params.merge(:port => 81)
     assert_sent_request_info_for @request
  end

   should "send request data for automatic notification" do
     Airbrake.configuration.environment_name = "production"
     params = { 'controller' => "airbrake_test", 'action' => "index" }
     @app = AirbrakeTestController.action(:boom)
     get "/", params
     assert_sent_request_info_for @request
   end

   should "send request data for automatic notification with non-standard port" do
     Airbrake.configuration.environment_name = "production"
     params = { 'controller' => "airbrake_test", 'action' => "index" }
     @app = AirbrakeTestController.action(:boom)
     get "/", params, {"SERVER_PORT" => 81}
     assert_sent_request_info_for @request
     assert_sent_element 81, "/notice/request/cgi-data/var[@key = 'SERVER_PORT']"
   end

  # TODO: remove this since this should be tested in integration tests
  # should "use standard rails logging filters on params and session and env" do
  #   Airbrake.configuration.environment_name = "production"
  #   filtered_params = { "abc" => "123",
  #                       "def" => "456",
  #                       "ghi" => "[FILTERED]" }

  #   filtered_session = { "abc" => "123",
  #                        "ghi" => "[FILTERED]" }
  #   ENV['ghi'] = 'abc'
  #   filtered_env = { 'ghi' => '[FILTERED]' }
  #   filtered_cgi = { 'REQUEST_METHOD' => '[FILTERED]' }

  #   params = { "abc" => "123",
  #              "def" => "456",
  #              "ghi" => "789" }

  #   @app = AirbrakeTestController.action(:boom)

  #   get "/",
  #   params.merge(:session => { "abc" => "122",
  #                "ghi" => "789" },:filter => "yes"),
  #   {"action_dispatch.parameter_filter" => [:ghi, :request_method]}
  #   assert_sent_hash filtered_params, '/notice/request/params'
  #   assert_sent_hash filtered_cgi, '/notice/request/cgi-data'
  #   assert_sent_hash filtered_session, '/notice/request/session'
  # end

  # context "for a local error with development lookup enabled" do
  #   setup do
  #     Airbrake.configuration.development_lookup = true
  #     Airbrake.stubs(:build_lookup_hash_for).returns({ :awesome => 2 })

  #     @response = process_action_with_automatic_notification(:local => true)
  #   end

  #   should "append custom CSS and JS to response body for a local error" do
  #     assert_match /text\/css/, @response
  #     assert_match /text\/javascript/, @response
  #   end

  #   should "contain host, API key and notice JSON" do
  #     assert_match Airbrake.configuration.host.to_json, @response
  #     assert_match Airbrake.configuration.api_key.to_json, @response
  #     assert_match ({ :awesome => 2 }).to_json, @response
  #   end
  # end

  # context "for a local error with development lookup disabled" do
  #   setup do
  #     Airbrake.configuration.development_lookup = false

  #     @response = process_action_with_automatic_notification(:local => true)
  #   end

  #   should "not append custom CSS and JS to response for a local error" do
  #     assert_no_match /text\/css/, @response
  #     assert_no_match /text\/javascript/, @response
  #   end
  # end

  # should "call session.to_hash if available" do
  #   hash_data = {:key => :value}

  #   session = ActionController::TestSession.new
  #   ActionController::TestSession.stubs(:new).returns(session)
  #   session.stubs(:to_hash).returns(hash_data)

  #   Airbrake.configuration.environment_name = "production"

  #   @app = AirbrakeTestController.action(:boom)
  #   get '/'

  #   assert_received(session, :to_hash)
  #   assert_received(session, :data) { |expect| expect.never }
  #   assert_caught_and_sent
  # end

  # should "call session.data if session.to_hash is undefined" do
  #   hash_data = {:key => :value}

  #   session = ActionController::TestSession.new
  #   ActionController::TestSession.stubs(:new).returns(session)
  #   session.stubs(:data).returns(hash_data)
  #   if session.respond_to?(:to_hash)
  #     class << session
  #       undef to_hash
  #     end
  #   end

  #   Airbrake.configuration.environment_name = "production"

  #   @app = AirbrakeTestController.action(:boom)
  #   get '/'

  #   assert_received(session, :to_hash) { |expect| expect.never }
  #   assert_received(session, :data) { |expect| expect.at_least_once }
  #   assert_caught_and_sent
  # end
end
