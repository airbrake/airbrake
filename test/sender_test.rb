require File.dirname(__FILE__) + '/helper'

class SenderTest < Test::Unit::TestCase

  def setup
    reset_config
  end

  def build_sender(args = {})
    HoptoadNotifier::Sender.new
  end

  def send_exception(args = {})
    notice = args.delete(:notice) || build_notice_data
    sender = args.delete(:sender) || build_sender(args)
    sender.send_to_hoptoad(notice)
    sender
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

  should "post to Hoptoad when using an HTTP proxy" do
    response = stub(:body => 'body')
    http     = stub(:post          => response,
                    :read_timeout= => nil,
                    :open_timeout= => nil,
                    :use_ssl=      => nil)
    proxy    = stub(:new => http)
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

end
