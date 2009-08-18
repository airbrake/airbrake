require File.dirname(__FILE__) + '/helper'

class CatcherTest < Test::Unit::TestCase

  include DefinesConstants

  def setup
    super
    reset_config
    HoptoadNotifier.sender = CollectingSender.new
  end

  def ignore(exception_class)
    HoptoadNotifier.configuration.ignore << exception_class
  end

  def build_controller_class(&definition)
    returning Class.new(ActionController::Base) do |klass|
      klass.__send__(:include, HoptoadNotifier::Catcher)
      klass.class_eval(&definition) if definition
      define_constant('HoptoadTestController', klass)
    end
  end

  def assert_sent_session_data(data)
    assert_not_nil notice = last_sent_notice_data, "should send a notice"
    assert_not_nil notice['session'], "should send a session, (got #{notice.inspect})"
    assert_equal data, notice['session']['data']
  end

  def assert_sent_parameter_data(data)
    assert_not_nil notice = last_sent_notice_data, "should send a notice"
    assert_not_nil request = notice['request'], "should send a request, (got #{notice.inspect})"
    assert_equal data, request['params']
  end

  def sender
    HoptoadNotifier.sender
  end

  def last_sent_notice_yaml
    sender.collected.last
  end

  def last_sent_notice_data
    YAML.load(last_sent_notice_yaml)['notice']
  end

  def process_action(opts = {}, &action)
    opts[:request]  ||= ActionController::TestRequest.new
    opts[:response] ||= ActionController::TestResponse.new
    klass = build_controller_class do
      cattr_accessor :local
      define_method(:index, &action)
      def local_request?
        local
      end
    end
    if opts[:user_agent]
      if opts[:request].respond_to?(:user_agent=)
        opts[:request].user_agent = opts[:user_agent]
      else
        opts[:request].env["HTTP_USER_AGENT"] = opts[:user_agent]
      end
    end
    klass.consider_all_requests_local = opts[:all_local]
    klass.local                       = opts[:local]
    controller = klass.new
    controller.stubs(:rescue_action_in_public_without_hoptoad)
    opts[:request].query_parameters = opts[:request].query_parameters.merge(opts[:params] || {})
    opts[:request].session.clear
    opts[:request].session.merge!(opts[:session] || {})
    controller.process(opts[:request], opts[:response])
    controller
  end

  def process_action_with_manual_notification(args = {})
    process_action(args) do
      notify_hoptoad(:error_message => 'fail')
      # Rails will raise a template error if we don't render something
      render :nothing => true
    end
  end

  def process_action_with_automatic_notification(args = {})
    process_action(args) { raise "Hello" }
  end

  should "deliver notices from exceptions raised in public requests" do
    process_action_with_automatic_notification
    assert_caught_and_sent
  end

  should "not deliver notices from exceptions in local requests" do
    process_action_with_automatic_notification(:local => true)
    assert_caught_and_not_sent
  end

  should "not deliver notices from exceptions when all requests are local" do
    process_action_with_automatic_notification(:all_local => true)
    assert_caught_and_not_sent
  end

  should "not deliver notices from actions that don't raise" do
    controller = process_action { render :text => 'Hello' }
    assert_caught_and_not_sent
    assert_equal 'Hello', controller.response.body
  end

  should "not deliver ignored exceptions raised by actions" do
    ignore(RuntimeError)
    process_action_with_automatic_notification
    assert_caught_and_not_sent
  end

  should "deliver ignored exception raised manually" do
    ignore(RuntimeError)
    process_action_with_manual_notification
    assert_caught_and_sent
  end

  should "deliver manually sent notices in public requests" do
    process_action_with_manual_notification
    assert_caught_and_sent
  end

  should "not deliver manually sent notices in local requests" do
    process_action_with_manual_notification(:local => true)
    assert_caught_and_not_sent
  end

  should "not deliver manually sent notices when all requests are local" do
    process_action_with_manual_notification(:all_local => true)
    assert_caught_and_not_sent
  end

  should "continue with default behavior after delivering an exception" do
    controller = process_action_with_automatic_notification(:public => true)
    # TODO: can we test this without stubbing?
    assert_received(controller, :rescue_action_in_public_without_hoptoad)
  end

  should "not create actions from Hoptoad methods" do
    controller = build_controller_class.new
    assert_equal [], HoptoadNotifier::Catcher.instance_methods
  end

  should "ignore exceptions when user agent is being ignored by regular expression" do
    HoptoadNotifier.configuration.ignore_user_agent_only = [/Ignored/]
    process_action_with_automatic_notification(:user_agent => 'ShouldBeIgnored')
    assert_caught_and_not_sent
  end

  should "ignore exceptions when user agent is being ignored by string" do
    HoptoadNotifier.configuration.ignore_user_agent_only = ['IgnoredUserAgent']
    process_action_with_automatic_notification(:user_agent => 'IgnoredUserAgent')
    assert_caught_and_not_sent
  end

  should "not ignore exceptions when user agent is not being ignored" do
    HoptoadNotifier.configuration.ignore_user_agent_only = ['IgnoredUserAgent']
    process_action_with_automatic_notification(:user_agent => 'NonIgnoredAgent')
    assert_caught_and_sent
  end

  should "send session data for manual notifications" do
    data = { 'one' => 'two' }
    process_action_with_manual_notification(:session => data)
    assert_sent_session_data data
  end

  should "send session data for automatic notification" do
    data = { 'one' => 'two' }
    process_action_with_automatic_notification(:session => data)
    assert_sent_session_data data
  end

  should "send request data for manual notification" do
    params = { 'controller' => "users", 'action' => "create" }
    process_action_with_manual_notification(:params => params)
    assert_sent_parameter_data params
  end

  should "send request data for automatic notification" do
    params = { 'controller' => "users", 'action' => "create" }
    process_action_with_automatic_notification(:params => params)
    assert_sent_parameter_data params
  end

end
