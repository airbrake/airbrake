module Airbrake
  # Middleware for Sinatra applications. Any errors raised by the upstream
  # application will be delivered to Airbrake and re-raised.

  # Synopsis:

  #   require 'sinatra'
  #   require 'airbrake'

  #   Airbrake.configure do |config|
  #     config.api_key = 'my api key'
  #   end

  #   use Airbrake::Sinatra

  #   get '/' do
  #     raise "Sinatra has left the building"
  #   end
  #
  # Use a standard Airbrake.configure call to configure your api key.
  class Sinatra < Rack

    def initialize(app)
      super
      Airbrake.configuration.environment_name = "#{app.settings.environment}"
      Airbrake.configuration.framework = "Sinatra: #{::Sinatra::VERSION}"
    end

    def framework_exception(env)
      env['sinatra.error']
    end
  end
end
