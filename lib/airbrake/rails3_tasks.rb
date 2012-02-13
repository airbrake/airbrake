require 'airbrake'
require File.join(File.dirname(__FILE__), 'shared_tasks')

namespace :airbrake do
  desc "Verify your gem installation by sending a test exception to the airbrake service"
  task :test => [:environment] do
    Rails.logger = defined?(ActiveSupport::TaggedLogging) ?
      ActiveSupport::TaggedLogging.new(Logger.new(STDOUT)) :
      Logger.new(STDOUT)
      
    Rails.logger.level = Logger::DEBUG
    Airbrake.configure(true) do |config|
      config.logger = Rails.logger
    end

    require './app/controllers/application_controller'

    class AirbrakeTestingException < RuntimeError; end

    unless Airbrake.configuration.api_key
      puts "Airbrake needs an API key configured! Check the README to see how to add it."
      exit
    end

    Airbrake.configuration.development_environments = []

    puts "Configuration:"
    Airbrake.configuration.to_hash.each do |key, value|
      puts sprintf("%25s: %s", key.to_s, value.inspect.slice(0, 55))
    end

    unless defined?(ApplicationController)
      puts "No ApplicationController found"
      exit
    end

    puts 'Setting up the Controller.'
    class ApplicationController
      # This is to bypass any filters that may prevent access to the action.
      prepend_before_filter :test_airbrake
      def test_airbrake
        puts "Raising '#{exception_class.name}' to simulate application failure."
        raise exception_class.new, 'Testing airbrake via "rake airbrake:test". If you can see this, it works.'
      end

      # def rescue_action(exception)
      #   rescue_action_in_public exception
      # end

      # Ensure we actually have an action to go to.
      def verify; end

      # def consider_all_requests_local
      #   false
      # end

      # def local_request?
      #   false
      # end

      def exception_class
        exception_name = ENV['EXCEPTION'] || "AirbrakeTestingException"
        Object.const_get(exception_name)
      rescue
        Object.const_set(exception_name, Class.new(Exception))
      end

      def logger
        nil
      end
    end
    class AirbrakeVerificationController < ApplicationController; end

    Rails.application.routes_reloader.execute_if_updated
    Rails.application.routes.draw do
      match 'verify' => 'application#verify', :as => 'verify'
    end

    puts 'Processing request.'
    env = Rack::MockRequest.env_for("/verify")

    Rails.application.call(env)
  end
end

