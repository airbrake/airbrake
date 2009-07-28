require File.dirname(__FILE__) + '/helper'

class FakeLogger
  def info(*args);  end
  def debug(*args); end
  def warn(*args);  end
  def error(*args); end
end

RAILS_DEFAULT_LOGGER = FakeLogger.new

class NotifierTest < Test::Unit::TestCase

  def setup
    reset_config
  end

  def send_exception(exception = nil)
    exception ||= build_exception
    # TODO: remove this stub
    HoptoadNotifier::DummySender.any_instance.stubs(:public_environment? => true)
    HoptoadNotifier.notify(exception)
  end

  def sender
    HoptoadNotifier.sender
  end

  def assert_sent(exception_data)
    assert_received(sender, :send_to_hoptoad) {|expect| expect.with(exception_data) }
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

  should "make sure the exception is munged into a hash" do
    stub_sender!
    exception = build_exception
    options   = HoptoadNotifier.default_notice_options.merge({
      :backtrace     => exception.backtrace,
      :environment   => ENV.to_hash,
      :error_class   => exception.class.name,
      :error_message => "#{exception.class.name}: #{exception.message}",
      :api_key       => HoptoadNotifier.api_key,
    })

    send_exception exception

    assert_sent :notice => options
  end

  should "parse massive one-line exceptions into multiple lines" do
    exception = build_exception
    original_backtrace = "one big line\n   separated\n      by new lines\nand some spaces"
    expected_backtrace = ["one big line", "separated", "by new lines", "and some spaces"]
    exception.set_backtrace [original_backtrace]
    stub_sender!

    options = HoptoadNotifier.default_notice_options.merge({
      :backtrace     => expected_backtrace,
      :environment   => ENV.to_hash,
      :error_class   => exception.class.name,
      :error_message => "#{exception.class.name}: #{exception.message}",
      :api_key       => HoptoadNotifier.api_key,
    })

    send_exception exception
    assert_sent :notice => options
  end

  should "send sensible defaults without an exception" do
    stub_sender!
    backtrace = caller
    options   = { :error_message => "123",
                  :backtrace => backtrace }
    send_exception(:error_message => "123", :backtrace => backtrace)

    # we can't use #has_entries from Mocha here, because it's all under a :notice key
    received = nil
    assert_received(sender, :send_to_hoptoad) do |expect|
      expect.with {|params| received = params }
      true
    end
    assert_not_nil received[:notice], "No notice data was sent"
    options.each do |key, value|
      assert_equal value, received[:notice][key], "Incorrect value for notice[#{key}]"
    end
  end

end
