Feature: Use the notifier in a plain Rack app
  	
 Scenario: Rescue and exception in a Rack app

   Given the following Rack app:
     """
     require 'logger'
     require 'rack'
     require 'airbrake'
	  	
     Airbrake.configure do |config|
       config.api_key = 'my_api_key'
       config.logger = Logger.new STDOUT
     end
	  	
     app = Rack::Builder.app do
       use Airbrake::Rack
       run lambda { |env| raise "Rack down" }
     end

     """
   When I perform a Rack request to "http://example.com:123/test/index?param=value"
   Then I should receive a Airbrake notification
	  	
 Scenario: Ignore user agents

   Given the following Rack app:
     """
     require 'logger'
     require 'rack'
     require 'airbrake'
	  	
     Airbrake.configure do |config|
       config.api_key = 'my_api_key'
       config.ignore_user_agent << /ignore/
       config.logger = Logger.new STDOUT
     end
	  	
     class Mock
       class AppendUserAgent
         def initialize(app)
           @app = app
         end
	  	
         def call(env)
           env["HTTP_USER_AGENT"] = "ignore"
           @app.call(env)
         end
       end
     end
	  	
     app = Rack::Builder.app do
       use Airbrake::Rack
       use Mock::AppendUserAgent
       run lambda { |env| raise "Rack down" }
     end
	  	
     """
   When I perform a Rack request to "http://example.com:123/test/index?param=value"
   Then I should not receive a Airbrake notification
