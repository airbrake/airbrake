require File.dirname(__FILE__) + '/helper'

class CatcherTest < Test::Unit::TestCase

  include DefinesConstants

  class CollectingSender
    attr_reader :collected

    def initialize
      @collected = []
    end

    def send_to_hoptoad(data)
      @collected << data
    end
  end

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
    klass.consider_all_requests_local = opts[:all_local]
    klass.local                       = opts[:local]
    controller = klass.new
    controller.stubs(:rescue_action_in_public_without_hoptoad)
    controller.process(opts[:request], opts[:response])
    controller
  end

  should "deliver notices from exceptions raised in public requests" do
    process_action { raise "Hello" }
    assert_caught_and_sent
  end

  should "not deliver notices from exceptions in local requests" do
    process_action(:local => true) { raise "Hello" }
    assert_caught_and_not_sent
  end

  should "not deliver notices from exceptions when all requests are local" do
    process_action(:all_local => true) { raise "Hello" }
    assert_caught_and_not_sent
  end

  should "not deliver notices from actions that don't raise" do
    controller = process_action { render :text => 'Hello' }
    assert_caught_and_not_sent
    assert_equal 'Hello', controller.response.body
  end

  should "not deliver ignored exceptions raised by actions" do
    ignore(RuntimeError)
    process_action { raise "Hello" }
    assert_caught_and_not_sent
  end

  should "deliver ignored exception raised manually" do
    ignore(RuntimeError)
    process_action { notify_hoptoad(:message => 'uh oh') }
    assert_caught_and_sent
  end

  should "deliver manually sent notices in public requests" do
    process_action do
      notify_hoptoad(:error_message => 'Yeah')
      render :text => 'Hello'
    end
    assert_caught_and_sent
  end

  should "not deliver manually sent notices in local requests" do
    process_action(:local => true) do
      notify_hoptoad(:error_message => 'Yeah')
      render :text => 'Hello'
    end
    assert_caught_and_not_sent
  end

  should "not deliver manually sent notices when all requests are local" do
    process_action(:all_local => true) do
      notify_hoptoad(:error_message => 'Yeah')
      render :text => 'Hello'
    end
    assert_caught_and_not_sent
  end

  should "continue with default behavior after delivering an exception" do
    controller = process_action(:public => true) do
      raise 'Oh no'
    end
    # TODO: can we test this without stubbing?
    assert_received(controller, :rescue_action_in_public_without_hoptoad)
  end

  should "not create actions from Hoptoad methods" do
    controller = build_controller_class.new
    assert_equal [], HoptoadNotifier::Catcher.instance_methods
  end

  should "pass the request to the notifier" do
    stub_notice!
    controller = process_action(:public => true) do
      raise 'Oh no'
    end
    assert_received(HoptoadNotifier::Notice, :new) do |expect|
      expect.with(has_entries(:request => controller.request))
    end
  end

  def assert_caught_and_sent
    assert !HoptoadNotifier.sender.collected.empty?
  end

  def assert_caught_and_not_sent
    assert HoptoadNotifier.sender.collected.empty?
  end

end
