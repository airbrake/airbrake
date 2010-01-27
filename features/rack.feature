Feature: Use the notifier in a plain Rack app

  Background:
    Given I have built and installed the "hoptoad_notifier" gem

  Scenario: Rescue and exception in a Rack app
    Given the following Rack app:
      """
      require 'rack'
      require 'hoptoad_notifier'

      HoptoadNotifier.configure do |config|
        config.api_key = 'my_api_key'
      end

      app = Rack::Builder.app do
        use HoptoadNotifier::Rack
        run lambda { |env| raise "Rack down" }
      end
      """
    When I perform a Rack request to "http://example.com:123/test/index?param=value"
    Then I should receive the following Hoptoad notification:
      | error message | RuntimeError: Rack down                       |
      | error class   | RuntimeError                                  |
      | parameters    | param: value                                  |
      | url           | http://example.com:123/test/index?param=value |

