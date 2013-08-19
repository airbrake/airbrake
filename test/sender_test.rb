require File.expand_path '../helper', __FILE__

class SenderTest < Test::Unit::TestCase

  def setup
    reset_config
  end

  def build_sender(opts = {})
    Airbrake.configure do |conf|
      opts.each {|opt, value| conf.send(:"#{opt}=", value) }
    end
  end

  def send_exception(args = {})
    notice = args.delete(:notice) || build_notice_data
    notice.stubs(:to_xml)
    sender = args.delete(:sender) || build_sender(args)
    sender.send_to_airbrake(notice)
  end

  def stub_http(options = {})
    response = stub(:body => options[:body] || 'body')
    http = stub(:post          => response,
                :read_timeout= => nil,
                :open_timeout= => nil,
                :ca_file=      => nil,
                :verify_mode=  => nil,
                :use_ssl=      => nil)
    Net::HTTP.stubs(:new => http)
    http
  end

  should "post to Airbrake when using an HTTP proxy" do
    response = stub(:body => 'body')
    http     = stub(:post          => response,
                    :read_timeout= => nil,
                    :open_timeout= => nil,
                    :use_ssl=      => nil)
    proxy    = stub(:new => http)
    Net::HTTP.stubs(:Proxy => proxy)

    url = "http://api.airbrake.io:80#{Airbrake::Sender::NOTICES_URI}"
    uri = URI.parse(url)

    proxy_host = 'some.host'
    proxy_port = 88
    proxy_user = 'login'
    proxy_pass = 'passwd'

    send_exception(:proxy_host => proxy_host,
                   :proxy_port => proxy_port,
                   :proxy_user => proxy_user,
                   :proxy_pass => proxy_pass)
    assert_received(http, :post) do |expect|
      expect.with(uri.path, anything, Airbrake::Sender::HEADERS[:xml])
    end
    assert_received(Net::HTTP, :Proxy) do |expect|
      expect.with(proxy_host, proxy_port, proxy_user, proxy_pass)
    end
  end

  should "return the created group's id on successful posting" do
    stub_http(:body => '<id type="integer">3799307</id>')
    assert_equal "3799307", send_exception(:secure => false)
  end

  context "when using the XML API" do

    should "post to Airbrake with XML passed" do
      xml_notice = Airbrake::Notice.new(:error_class => "FooBar", :error_message => "Foo Bar").to_xml

      http = stub_http

      sender = build_sender
      sender.send_to_airbrake(xml_notice)

      assert_received(http, :post) do |expect|
        expect.with(anything, xml_notice, Airbrake::Sender::HEADERS[:xml])
      end
    end

    should "post to Airbrake with a Notice instance passed" do
      notice = Airbrake::Notice.new(:error_class => "FooBar", :error_message => "Foo Bar")

      http = stub_http

      sender = build_sender
      sender.send_to_airbrake(notice)

      assert_received(http, :post) do |expect|
        expect.with(anything, notice.to_xml, Airbrake::Sender::HEADERS[:xml])
      end
    end

  end

  context "when using new JSON API" do
    should "post to Airbrake with JSON passed" do
      json_notice = Airbrake::Notice.new(:error_class => "FooBar", :error_message => "Foo Bar").to_json

      http = stub_http

      sender = build_sender(:project_id => "PROJECT_ID", :host => "collect.airbrake.io")
      sender.send_to_airbrake(json_notice)

      assert_received(http, :post) do |expect|
        expect.with(anything, json_notice, Airbrake::Sender::HEADERS[:json])
      end

    end

    should "post to Airbrake with notice passed" do
      notice = Airbrake::Notice.new(:error_class => "FooBar", :error_message => "Foo Bar")

      http = stub_http

      sender = build_sender(:project_id => "PROJECT_ID", :host => "collect.airbrake.io")
      sender.send_to_airbrake(notice)

      assert_received(http, :post) do |expect|
        expect.with(anything, notice.to_json, Airbrake::Sender::HEADERS[:json])
      end

    end
  end

  context "when encountering exceptions: " do
    context "HTTP connection setup problems" do
      should "not be rescued" do
        proxy = stub()
        proxy.stubs(:new).raises(NoMemoryError)
        Net::HTTP.stubs(:Proxy => proxy)

        assert_raise NoMemoryError do
          build_sender.send(:setup_http_connection)
        end
      end

      should "be logged" do
        proxy = stub()
        proxy.stubs(:new).raises(RuntimeError)
        Net::HTTP.stubs(:Proxy => proxy)

        sender = build_sender
        sender.expects(:log)

        assert_raise RuntimeError do
          sender.send(:setup_http_connection)
        end

      end
    end

    context "unexpected exception sending problems" do
      should "be logged" do
        sender  = build_sender
        sender.stubs(:setup_http_connection).raises(RuntimeError.new)

        sender.expects(:log)
        send_exception(:sender => sender)
      end

      should "return nil no matter what" do
        sender  = build_sender
        sender.stubs(:setup_http_connection).raises(LocalJumpError)

        assert_nothing_thrown do
          assert_nil sender.send_to_airbrake(build_notice_data)
        end
      end
    end

    should "return nil on failed posting" do
      http = stub_http
      http.stubs(:post).raises(Errno::ECONNREFUSED)
      assert_equal nil, send_exception(:secure => false)
    end

    should "not fail when posting and a timeout exception occurs" do
      http = stub_http
      http.stubs(:post).raises(TimeoutError)
      assert_nothing_thrown do
        send_exception(:secure => false)
      end
    end

    should "not fail when posting and a connection refused exception occurs" do
      http = stub_http
      http.stubs(:post).raises(Errno::ECONNREFUSED)
      assert_nothing_thrown do
        send_exception(:secure => false)
      end
    end

    should "not fail when posting any http exception occurs" do
      http = stub_http
      Airbrake::Sender::HTTP_ERRORS.each do |error|
        http.stubs(:post).raises(error)
        assert_nothing_thrown do
          send_exception(:secure => false)
        end
      end
    end
  end

  context "SSL" do
    should "post to the right url for non-ssl" do
      http = stub_http
      url = "http://api.airbrake.io:80#{Airbrake::Sender::NOTICES_URI}"
      uri = URI.parse(url)
      send_exception(:secure => false)
      assert_received(http, :post) {|expect| expect.with(uri.path, anything, Airbrake::Sender::HEADERS[:xml]) }
    end

    should "post to the right path for ssl" do
      http = stub_http
      send_exception(:secure => true)
      assert_received(http, :post) {|expect| expect.with(Airbrake::Sender::NOTICES_URI, anything, Airbrake::Sender::HEADERS[:xml]) }
    end

    should "verify the SSL peer when the use_ssl option is set to true" do
      url = "https://api.airbrake.io#{Airbrake::Sender::NOTICES_URI}"
      uri = URI.parse(url)

      real_http = Net::HTTP.new(uri.host, uri.port)
      real_http.stubs(:post => nil)
      proxy = stub(:new => real_http)
      Net::HTTP.stubs(:Proxy => proxy)
      File.stubs(:exist?).with(OpenSSL::X509::DEFAULT_CERT_FILE).returns(false)

      send_exception(:secure => true)
      assert(real_http.use_ssl?)
      assert_equal(OpenSSL::SSL::VERIFY_PEER,        real_http.verify_mode)
      assert_equal(Airbrake.configuration.local_cert_path, real_http.ca_file)
    end

    should "use the default DEFAULT_CERT_FILE if asked to" do
      config = Airbrake::Configuration.new
      config.use_system_ssl_cert_chain = true
      sender = Airbrake::Sender.new(config)

      assert(sender.use_system_ssl_cert_chain?)

      http    = sender.send(:setup_http_connection)
      assert_not_equal http.ca_file, config.local_cert_path
    end

    should "verify the connection when the use_ssl option is set (VERIFY_PEER)" do
      sender  = build_sender(:secure => true)
      http    = sender.send(:setup_http_connection)
      assert_equal(OpenSSL::SSL::VERIFY_PEER, http.verify_mode)
    end

    should "use the default cert (OpenSSL::X509::DEFAULT_CERT_FILE) only if explicitly told to" do
      sender  = build_sender(:secure => true)
      http    = sender.send(:setup_http_connection)

      assert_equal(Airbrake.configuration.local_cert_path, http.ca_file)

      File.stubs(:exist?).with(OpenSSL::X509::DEFAULT_CERT_FILE).returns(true)
      sender  = build_sender(:secure => true, :use_system_ssl_cert_chain => true)
      http    = sender.send(:setup_http_connection)

      assert_not_equal(Airbrake.configuration.local_cert_path, http.ca_file)
      assert_equal(OpenSSL::X509::DEFAULT_CERT_FILE, http.ca_file)
    end

    should "connect to the right port for ssl" do
      stub_http
      send_exception(:secure => true)
      assert_received(Net::HTTP, :new) {|expect| expect.with("api.airbrake.io", 443) }
    end

    should "connect to the right port for non-ssl" do
      stub_http
      send_exception(:secure => false)
      assert_received(Net::HTTP, :new) {|expect| expect.with("api.airbrake.io", 80) }
    end

    should "use ssl if secure" do
      stub_http
      send_exception(:secure => true, :host => 'example.org')
      assert_received(Net::HTTP, :new) {|expect| expect.with('example.org', 443) }
    end

    should "not use ssl if not secure" do
      stub_http
      send_exception(:secure => false, :host => 'example.org')
      assert_received(Net::HTTP, :new) {|expect| expect.with('example.org', 80) }
    end
  end

  context "network timeouts" do
    should "default the open timeout to 2 seconds" do
      http = stub_http
      send_exception
      assert_received(http, :open_timeout=) {|expect| expect.with(2) }
    end

    should "default the read timeout to 5 seconds" do
      http = stub_http
      send_exception
      assert_received(http, :read_timeout=) {|expect| expect.with(5) }
    end

    should "allow override of the open timeout" do
      http = stub_http
      send_exception(:http_open_timeout => 4)
      assert_received(http, :open_timeout=) {|expect| expect.with(4) }
    end

    should "allow override of the read timeout" do
      http = stub_http
      send_exception(:http_read_timeout => 10)
      assert_received(http, :read_timeout=) {|expect| expect.with(10) }
    end
  end
end
