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

  Scenario: Warnings when environment name wasn't determined automatically
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

      class DummyMiddleware
         def initialize(app)
            @app = app
         end

         def call(env)
            @app.call(env)
         end
      end

      class FontaneApp < Sinatra::Base

        use Airbrake::Sinatra

        use DummyMiddleware

        set :environment, :production

        get "/test/index" do
          raise "Sinatra has left the building"
        end
      end

      app = FontaneApp
      """
      When I perform a Rack request to "http://example.com:123/test/index?param=value"
      Then I should receive a Airbrake notification
      And the output should contain "Please set your environment name manually"

  Scenario: Give precendence to environment name that was first set
    Given the following Rack app:
      """
      require 'sinatra/base'
      require 'airbrake'
      require 'logger'

      Airbrake.configure do |config|
        config.api_key = 'my_api_key'
        config.logger  = Logger.new STDOUT
        config.environment_name = "staging"
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
    And the output should contain "Env: staging"
