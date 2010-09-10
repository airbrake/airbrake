Feature: Use the notifier in a Sinatra app

  Background:
    Given I have built and installed the "hoptoad_notifier" gem

  Scenario: Rescue an exception in a Sinatra app
    Given the following Rack app:
      """
      require 'sinatra/base'
      require 'hoptoad_notifier'

      HoptoadNotifier.configure do |config|
        config.api_key = 'my_api_key'
      end

      class FontaneApp < Sinatra::Base
        use HoptoadNotifier::Rack
        enable :raise_errors

        get "/test/index" do
          raise "Sinatra has left the building"
        end
      end

      app = FontaneApp
      """
    When I perform a Rack request to "http://example.com:123/test/index?param=value"
    Then I should receive the following Hoptoad notification:
      | error message | RuntimeError: Sinatra has left the building   |
      | error class   | RuntimeError                                  |
      | parameters    | param: value                                  |
      | url           | http://example.com:123/test/index?param=value |

