Feature: Use the notifier in a Sinatra app

  Scenario: Rescue an exception in a Sinatra app
    Given the following Rack app:
      """
      require 'sinatra/base'
      require 'airbrake'
      require 'logger'

      Airbrake.configure do |config|
        config.api_key = 'my_api_key' 
        config.logger  = Logger.new STDOUT
        config.development_environments = []
      end

      class FontaneApp < Sinatra::Base
        use Airbrake::Sinatra

        get "/test/index" do
          raise "Sinatra has left the building"
        end
      end

      app = FontaneApp
      """
    When I perform a Rack request to "http://example.com:123/test/index?param=value"
    Then I should receive a Airbrake notification
  
  Scenario: Catching environment name in modular Sinatra app
    Given the following Rack app:
      """
      require 'sinatra/base'
      require 'airbrake'
      require 'logger'

      Airbrake.configure do |config|
        config.api_key = 'my_api_key' 
        config.logger  = Logger.new STDOUT
      end

      class FontaneApp < Sinatra::Base
        use Airbrake::Sinatra

        set :environment, :production

        get "/test/index" do
          raise "Sinatra has left the building"
        end
      end

      app = FontaneApp
      """
    When I perform a Rack request to "http://example.com:123/test/index?param=value"
    Then I should receive a Airbrake notification
    And the output should contain "Env: production"
