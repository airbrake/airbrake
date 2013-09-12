module Airbrake
  # Middleware for Rack applications. Any errors raised by the upstream
  # application will be delivered to Airbrake and re-raised.
  #
  # Synopsis:
  #
  #   require 'rack'
  #   require 'airbrake'
  #
  #   Airbrake.configure do |config|
  #     config.api_key = 'my_api_key'
  #   end
  #
  #   app = Rack::Builder.app do
  #     run lambda { |env| raise "Rack down" }
  #   end
  #
  #   use Airbrake::Rack
  #   run app
  #
  # Use a standard Airbrake.configure call to configure your api key.
  class Rack
    def initialize(app)
      @app = app
      Airbrake.configuration.framework = "Rack: #{::Rack.release}"
    end

    def ignored_user_agent?(env)
      true if Airbrake.
        configuration.
        ignore_user_agent.
        flatten.
        any? { |ua| ua === env['HTTP_USER_AGENT'] }
    end

    def notify_airbrake(exception, env)
      unless ignored_user_agent?(env)
        Airbrake.notify_or_ignore(exception, :rack_env => env)
      end
    end

    def call(env)
      begin
        response = @app.call(env)
      rescue Exception => raised
        env['airbrake.error_id'] = notify_airbrake(raised, env)
        raise raised
      end

      if framework_exception(env)
        env['airbrake.error_id'] = notify_airbrake(framework_exception(env), env)
      end

      response
    end

    def framework_exception(env)
      env['rack.exception'] || env['sinatra.error']
    end

  end
end
