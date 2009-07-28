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
    # assert_received(sender, :send_to_hoptoad) {|expect| expect.with(exception_data) }
    # we can't use #has_entries from Mocha here, because it's all under a :notice key
    received = nil
    assert_received(sender, :send_to_hoptoad) do |expect|
      expect.with do |params|
        received = params
        true
      end
    end
    assert_not_nil received[:notice], "No notice data was sent"
    exception_data.each do |key, value|
      assert_equal value, received[:notice][key], "Incorrect value for notice[#{key}]"
    end
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
    clear_backtrace_filters
    exception = build_exception
    options   = HoptoadNotifier.default_notice_options.merge({
      :backtrace     => exception.backtrace,
      :environment   => ENV.to_hash,
      :error_class   => exception.class.name,
      :error_message => "#{exception.class.name}: #{exception.message}",
      :api_key       => HoptoadNotifier.configuration.api_key,
    })

    send_exception exception

    assert_sent options
  end

  should "parse massive one-line exceptions into multiple lines" do
    exception = build_exception
    original_backtrace = "one big line\n   separated\n      by new lines\nand some spaces"
    expected_backtrace = ["one big line", "separated", "by new lines", "and some spaces"]
    exception.set_backtrace [original_backtrace]
    stub_sender!
    clear_backtrace_filters

    options = HoptoadNotifier.default_notice_options.merge({
      :backtrace     => expected_backtrace,
      :environment   => ENV.to_hash,
      :error_class   => exception.class.name,
      :error_message => "#{exception.class.name}: #{exception.message}",
      :api_key       => HoptoadNotifier.configuration.api_key,
    })

    send_exception exception
    assert_sent options
  end

  should "send sensible defaults without an exception" do
    stub_sender!
    clear_backtrace_filters
    backtrace = caller
    options   = { :error_message => "123",
                  :backtrace => backtrace }
    send_exception(:error_message => "123", :backtrace => backtrace)

    assert_sent options
  end

  [File.open(__FILE__), Proc.new { puts "boo!" }, Module.new].each do |object|
    should "convert #{object.class} to a string when cleaning environment" do
      dummy = create_dummy
      HoptoadNotifier.configure {}
      notice = create_dummy.send(:normalize_notice, {})
      notice[:environment][:strange_object] = object

      filtered_notice = create_dummy.send(:clean_non_serializable_data, notice)
      assert_equal object.to_s, filtered_notice[:environment][:strange_object]
    end
  end

  [123, "string", 123_456_789_123_456_789, [:a, :b], {:a => 1}, HashWithIndifferentAccess.new].each do |object|
    should "not remove #{object.class} when cleaning environment" do
      dummy = create_dummy
      HoptoadNotifier.configure {}
      notice = dummy.send(:normalize_notice, {})
      notice[:environment][:strange_object] = object

      assert_equal object, dummy.send(:clean_non_serializable_data, notice)[:environment][:strange_object]
    end
  end

  should "remove notifier trace when cleaning backtrace" do
    reset_config
    dummy = create_dummy
    notice = dummy.send(:normalize_notice, {})

    assert notice[:backtrace].grep(%r{lib/hoptoad_notifier.rb}).any?, notice[:backtrace].inspect

    dirty_backtrace = dummy.send(:clean_hoptoad_backtrace, notice[:backtrace])
    dirty_backtrace.each do |line|
      assert_no_match %r{lib/hoptoad_notifier.rb}, line
    end
  end

  should "yield and save a configuration when configuring" do
    yielded_configuration = nil
    HoptoadNotifier.configure do |config|
      yielded_configuration = config
    end

    assert_kind_of HoptoadNotifier::Configuration, yielded_configuration
    assert_equal yielded_configuration, HoptoadNotifier.configuration
  end

  should "add filters to the backtrace_filters" do
    dummy = create_dummy
    HoptoadNotifier.configure do |config|
      config.filter_backtrace do |line|
        line = "1234"
      end
    end

    assert_equal %w(1234 1234), dummy.send(:clean_hoptoad_backtrace, %w(foo bar))
  end

  should "use standard rails logging filters on params and env" do
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

  should "filter params" do
    dummy = create_dummy
    HoptoadNotifier.configure do |config|
      config.params_filters << 'abc'
      config.params_filters << 'def'
    end

    assert_equal({ :abc => "[FILTERED]", :def => "[FILTERED]", :ghi => "789" },
                 dummy.send(:clean_hoptoad_params, :abc => "123", :def => "456", :ghi => "789"))
  end

  should "filter environment data" do
    dummy = create_dummy

    HoptoadNotifier.configure do |config|
      config.environment_filters << "secret"
      config.environment_filters << "supersecret"
    end

    assert_equal({ :secret => "[FILTERED]", :supersecret => "[FILTERED]", :ghi => "789" },
                 dummy.send(:clean_hoptoad_environment, :secret      => "123",
                                                        :supersecret => "456",
                                                        :ghi         => "789"))
  end

  should "configure the sender" do
    sender = stub_sender
    HoptoadNotifier::Sender.stubs(:new => sender)
    configuration = nil

    HoptoadNotifier.configure { |yielded_config| configuration = yielded_config }

    assert_received(HoptoadNotifier::Sender, :new) { |expect| expect.with(configuration) }
    assert_equal sender, HoptoadNotifier.sender
  end
end
