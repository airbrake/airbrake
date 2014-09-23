require 'airbrake'
require File.join(File.dirname(__FILE__), 'shared_tasks')

def stub_rake_exception_handling!
  # Override error handling in Rake so we don't clutter STDERR
  # with unnecesarry stack trace
  Rake.application.instance_eval do
    class << self
      def display_error_message_silent(exception)
        puts exception
      end
      alias_method :display_error_message_old, :display_error_message
      alias_method :display_error_message, :display_error_message_silent
    end
  end
end

def unstub_rake_exception_handling!
  # Turns Rake exception handling back to normal
  Rake.application.instance_eval do
    class << self
      def display_error_message_silent(exception)
        display_error_message_old(exception)
      end
    end
  end
end

namespace :airbrake do
  desc "Verify your gem installation by sending a test exception to the airbrake service"
  task :test => [:environment] do

    stub_rake_exception_handling!

    Rails.logger = defined?(ActiveSupport::TaggedLogging) ?
      ActiveSupport::TaggedLogging.new(Logger.new(STDOUT)) :
      Logger.new(STDOUT)

    def wait_for_threads
      # if using multiple threads, we have to wait for
      # them to finish
      if GirlFriday.status.empty?
        Thread.list.each do |thread|
          thread.join unless thread == Thread.current
        end
      else
        GirlFriday.shutdown!
      end
    end

    # Sets up verbose logging
    Rails.logger.level = Logger::DEBUG
    Airbrake.configure(true) do |config|
      config.logger = Rails.logger
    end

    # Override Rails exception middleware, so we stop cluttering STDOUT
    # with stack trace from Rails
    class ActionDispatch::DebugExceptions; def call(env); @app.call(env); end; end
    class ActionDispatch::ShowExceptions; def call(env); @app.call(env); end; end

    require './app/controllers/application_controller'

    class AirbrakeTestingException < RuntimeError; end

    # Checks if api_key is set
    unless Airbrake.configuration.api_key
      puts "Airbrake needs an API key configured! Check the README to see how to add it."
      exit
    end

    # Enables Airbrake reporting on all environments,
    # so we don't have to worry about invoking the task in production
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
        raise exception_class.new, "\nTesting airbrake via \"rake airbrake:test\"."\
                                   " If you can see this, it works."
      end

      # Ensure we actually have an action to go to.
      def verify; end

      def exception_class
        exception_name = ENV['EXCEPTION'] || "AirbrakeTestingException"
        Object.const_get(exception_name)
      rescue
        Object.const_set(exception_name, Class.new(Exception))
      end
    end

    Rails.application.routes.draw do
      get 'verify' => 'application#verify', :as => 'verify', :via => :get
    end

    puts 'Processing request.'

    config = Rails.application.config
    protocol = (config.respond_to?(:force_ssl) && config.force_ssl) ? 'https' : 'http'

    env = Rack::MockRequest.env_for("#{protocol}://www.example.com/verify")

    Rails.application.call(env)

    wait_for_threads if defined? GirlFriday

    unstub_rake_exception_handling!
  end
end

