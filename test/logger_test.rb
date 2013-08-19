require File.expand_path '../helper', __FILE__

class LoggerTest < Test::Unit::TestCase
  def stub_http(response, body = nil)
    response.stubs(:body => body) if body
    @http = stub(:post => response,
                 :read_timeout= => nil,
                 :open_timeout= => nil,
                 :use_ssl= => nil)
    Net::HTTP.stubs(:new).returns(@http)
  end

  def send_notice
    Airbrake.sender.send_to_airbrake({'foo' => "bar"})
  end

  def stub_verbose_log
    Airbrake.stubs(:write_verbose_log)
  end

  def configure
    Airbrake.configure { |config| }
  end

  should "report that notifier is ready when configured" do
    stub_verbose_log
    configure
    assert_logged(/Notifier (.*) ready/)
  end

  should "not report that notifier is ready when internally configured" do
    stub_verbose_log
    Airbrake.configure(true) { |config| }
    assert_not_logged(/.*/)
  end

  should "print environment info a successful notification without a body" do
    reset_config
    stub_verbose_log
    stub_http(Net::HTTPSuccess)
    send_notice
    assert_logged(/Environment Info:/)
    assert_not_logged(/Response from Airbrake:/)
  end

  should "print environment info on a failed notification without a body" do
    reset_config
    stub_verbose_log
    stub_http(Net::HTTPError)
    send_notice
    assert_logged(/Environment Info:/)
    assert_not_logged(/Response from Airbrake:/)
  end

  should "print environment info and response on a success with a body" do
    reset_config
    stub_verbose_log
    stub_http(Net::HTTPSuccess, 'test')
    send_notice
    assert_logged(/Environment Info:/)
    assert_logged(/Response from Airbrake:/)
  end

  should "print environment info and response on a failure with a body" do
    reset_config
    stub_verbose_log
    stub_http(Net::HTTPError, 'test')
    send_notice
    assert_logged(/Environment Info:/)
    assert_logged(/Response from Airbrake:/)
  end

  should "print information about the notice when Airbrake server fails" do
    stub_verbose_log
    stub_http(Net::HTTPError, "test")
    send_notice
    assert_logged(/Notice details:/)
  end
end
