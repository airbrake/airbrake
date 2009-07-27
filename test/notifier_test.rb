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

  def reset_config
    HoptoadNotifier.port = nil
    HoptoadNotifier.host = nil
    HoptoadNotifier.proxy_host = nil
    HoptoadNotifier.backtrace_filters.clear
    HoptoadNotifier.secure = false
  end

  def send_exception(exception = nil)
    exception ||= build_exception
    # TODO: remove this stub
    HoptoadNotifier::Sender.any_instance.stubs(:public_environment? => true)
    HoptoadNotifier.notify(exception)
  end

  def build_exception
    raise
  rescue => caught_exception
    caught_exception
  end

  def stub_sender
    # TODO: remove this stub
    HoptoadNotifier.stubs(:environment_info)
    returning HoptoadNotifier::Sender.new do |sender|
      HoptoadNotifier::Sender.stubs(:new => sender)
    end
  end

  def stub_http
    response = stub(:body => 'body')
    http = stub(:post          => response,
                :read_timeout= => nil,
                :open_timeout= => nil,
                :use_ssl=      => nil)
    Net::HTTP.stubs(:new => http)
    http
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
    sender    = stub_sender
    sender.stubs(:send_to_hoptoad => nil)
    exception = build_exception
    options   = HoptoadNotifier.default_notice_options.merge({
      :backtrace     => exception.backtrace,
      :environment   => ENV.to_hash,
      :error_class   => exception.class.name,
      :error_message => "#{exception.class.name}: #{exception.message}",
      :api_key       => HoptoadNotifier.api_key,
    })

    send_exception exception

    assert_received(sender, :send_to_hoptoad) {|expect| expect.with(:notice => options) }
  end

  should "parse massive one-line exceptions into multiple lines" do
    exception = build_exception
    original_backtrace = "one big line\n   separated\n      by new lines\nand some spaces"
    expected_backtrace = ["one big line", "separated", "by new lines", "and some spaces"]
    exception.set_backtrace [original_backtrace]
    sender = stub_sender
    sender.stubs(:send_to_hoptoad => nil)

    options = HoptoadNotifier.default_notice_options.merge({
      :backtrace     => expected_backtrace,
      :environment   => ENV.to_hash,
      :error_class   => exception.class.name,
      :error_message => "#{exception.class.name}: #{exception.message}",
      :api_key       => HoptoadNotifier.api_key,
    })

    send_exception exception
    assert_received(sender, :send_to_hoptoad) {|expect| expect.with(:notice => options) }
  end

  should "post to Hoptoad when using an HTTP proxy" do
    body = 'body'
    response = stub(:body => body)
    http = stub(:post => response, :read_timeout= => nil, :open_timeout= => nil, :use_ssl= => nil)
    proxy = stub
    proxy.stubs(:new).returns(http)

    Net::HTTP.stubs(:Proxy => proxy)
    url = "http://hoptoadapp.com:80/notices/"
    uri = URI.parse(url)
    send_exception
    assert_received(http, :post) { |expect| expect.with(uri.path, anything, HoptoadNotifier::HEADERS) }
    assert_received(Net::HTTP, :Proxy) do |expect|
      expect.with(
        HoptoadNotifier.proxy_host,
        HoptoadNotifier.proxy_port,
        HoptoadNotifier.proxy_user,
        HoptoadNotifier.proxy_pass
      )
    end
  end

  should "post to the right url for non-ssl" do
    http = stub_http
    HoptoadNotifier.secure = false
    url = "http://hoptoadapp.com:80/notices/"
    uri = URI.parse(url)
    send_exception
    assert_received(http, :post) {|expect| expect.with(uri.path, anything, HoptoadNotifier::HEADERS) }
  end

  should "post to the right path for ssl" do
    http = stub_http
    HoptoadNotifier.secure = false
    send_exception
    assert_received(http, :post) {|expect| expect.with("/notices/", anything, HoptoadNotifier::HEADERS) }
  end

  should "default the open timeout to 2 seconds" do
    http = stub_http
    HoptoadNotifier.http_open_timeout = nil
    send_exception
    assert_received(http, :open_timeout=) {|expect| expect.with(2) }
  end

  should "default the read timeout to 5 seconds" do
    http = stub_http
    HoptoadNotifier.http_read_timeout = nil
    send_exception
    assert_received(http, :read_timeout=) {|expect| expect.with(5) }
  end

  should "allow override of the open timeout" do
    http = stub_http
    HoptoadNotifier.http_open_timeout = 4
    send_exception
    assert_received(http, :open_timeout=) {|expect| expect.with(4) }
  end

  should "allow override of the read timeout" do
    http = stub_http
    HoptoadNotifier.http_read_timeout = 10
    send_exception
    assert_received(http, :read_timeout=) {|expect| expect.with(10) }
  end

  should "connect to the right port for ssl" do
    stub_http
    HoptoadNotifier.secure = true
    send_exception
    assert_received(Net::HTTP, :new) {|expect| expect.with("hoptoadapp.com", 443) }
  end

  should "connect to the right port for non-ssl" do
    stub_http
    HoptoadNotifier.secure = false
    send_exception
    assert_received(Net::HTTP, :new) {|expect| expect.with("hoptoadapp.com", 80) }
  end

  should "use ssl if secure" do
    stub_http
    HoptoadNotifier.secure = true
    HoptoadNotifier.host = 'example.org'
    send_exception
    assert_received(Net::HTTP, :new) {|expect| expect.with('example.org', 443) }
  end

  should "not use ssl if not secure" do
    stub_http
    HoptoadNotifier.secure = nil
    HoptoadNotifier.host = 'example.org'
    send_exception
    assert_received(Net::HTTP, :new) {|expect| expect.with('example.org', 80) }
  end

  should "send sensible defaults without an exception" do
    sender    = stub_sender
    sender.stubs(:notify_hoptoad => nil)
    backtrace = caller
    options   = {:error_message => "123",
                  :backtrace => backtrace}
    HoptoadNotifier.notify(:error_message => "123", :backtrace => backtrace)
    assert_received(sender, :notify_hoptoad) {|expect| expect.with(options) }
  end

end
