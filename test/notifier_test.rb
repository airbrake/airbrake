require File.dirname(__FILE__) + '/helper'

class NotifierTest < Test::Unit::TestCase

  def setup
    reset_config
  end

  # TODO: what does this test?
  should "send without rails environment" do
    assert_nothing_raised do
      HoptoadNotifier.environment_info
    end
  end

  should "send information about the notifier in the headers" do
    assert_equal "Hoptoad Notifier", HoptoadNotifier::HEADERS['X-Hoptoad-Client-Name']
    assert_equal HoptoadNotifier::VERSION, HoptoadNotifier::HEADERS['X-Hoptoad-Client-Version']
  end

  should "yield and save a configuration when configuring" do
    yielded_configuration = nil
    HoptoadNotifier.configure do |config|
      yielded_configuration = config
    end

    assert_kind_of HoptoadNotifier::Configuration, yielded_configuration
    assert_equal yielded_configuration, HoptoadNotifier.configuration
  end

  should_eventually "use standard rails logging filters on params and env" do
    ::HoptoadController.class_eval do
      filter_parameter_logging :ghi
    end
    controller = HoptoadController.new

    expected = {"notice" => {"request" => {"params" => {"abc" => "123", "def" => "456", "ghi" => "[FILTERED]"}},
                           "environment" => {"abc" => "123", "ghi" => "[FILTERED]"}}}
    notice   = {"notice" => {"request" => {"params" => {"abc" => "123", "def" => "456", "ghi" => "789"}},
                           "environment" => {"abc" => "123", "ghi" => "789"}}}
    assert controller.respond_to?(:filter_parameters)
    assert_equal( expected[:notice], controller.send(:clean_notice, notice)[:notice] )
  end

  should "configure the sender" do
    sender = stub_sender
    HoptoadNotifier::Sender.stubs(:new => sender)
    configuration = nil

    HoptoadNotifier.configure { |yielded_config| configuration = yielded_config }

    assert_received(HoptoadNotifier::Sender, :new) { |expect| expect.with(configuration) }
    assert_equal sender, HoptoadNotifier.sender
  end

  def stub_notice!
    returning stub('notice', :to_yaml => 'some yaml') do |notice|
      HoptoadNotifier::Notice.stubs(:new => notice)
    end
  end

  def assert_sent(notice, notice_args)
    assert_received(HoptoadNotifier::Notice, :new) {|expect| expect.with(notice_args) }
    assert_received(notice, :to_yaml)
    assert_received(HoptoadNotifier.sender, :send_to_hoptoad) {|expect| expect.with(notice.to_yaml) }
  end

  should "create and send a notice for an exception" do
    exception = build_exception
    stub_sender!
    notice = stub_notice!

    HoptoadNotifier.notify(exception)

    assert_sent notice, :exception => exception
  end

  should "create and send a notice for a hash" do
    notice = stub_notice!
    notice_args = { :error_message => 'uh oh' }
    stub_sender!

    HoptoadNotifier.notify(notice_args)

    assert_sent(notice, notice_args)
  end

  should "create and sent anotice for an exception and hash" do
    exception = build_exception
    notice = stub_notice!
    notice_args = { :error_message => 'uh oh' }
    stub_sender!

    HoptoadNotifier.notify(exception, notice_args)

    assert_sent(notice, notice_args.merge(:exception => exception))
  end
end
