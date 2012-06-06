Feature: Use the notifier in a plain Rack app

  Background:
    Given I have built and installed the "airbrake" gem

  Scenario: Rescue and exception in a Rack app
    Given the following Rack app:
      """
      require 'rack'
      require 'airbrake'

      Airbrake.configure do |config|
        config.api_key = 'my_api_key'
      end

      app = Rack::Builder.app do
        use Airbrake::Rack
        run lambda { |env| raise "Rack down" }
      end
      """
    When I perform a Rack request to "http://example.com:123/test/index?param=value"
    Then I should receive a Airbrake notification

