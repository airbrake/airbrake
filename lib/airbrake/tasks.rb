require 'airbrake'
require File.join(File.dirname(__FILE__), 'shared_tasks')

namespace :airbrake do
  desc "Verify your gem installation by sending a test exception to the airbrake service"
  task :test => ['airbrake:log_stdout', :environment] do
    RAILS_DEFAULT_LOGGER.level = Logger::DEBUG

    require 'action_controller/test_process'

    Dir["app/controllers/application*.rb"].each { |file| require(File.expand_path(file)) } 

    class AirbrakeTestingException < RuntimeError; end

    unless Airbrake.configuration.api_key
      puts "Airbrake needs an API key configured! Check the README to see how to add it."
      exit
    end

    Airbrake.configuration.development_environments = []

    catcher = Airbrake::Rails::ActionControllerCatcher
    in_controller = ApplicationController.included_modules.include?(catcher)
    in_base = ActionController::Base.included_modules.include?(catcher)
    if !in_controller || !in_base
      puts "Rails initialization did not occur"
      exit
    end

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

      def rescue_action(exception)
        rescue_action_in_public exception
      end

      # Ensure we actually have an action to go to.
      def verify; end

      def consider_all_requests_local
        false
      end

      def local_request?
        false
      end

      def exception_class
        exception_name = ENV['EXCEPTION'] || "AirbrakeTestingException"
        exception_name.split("::").inject(Object){|klass, name| klass.const_get(name)}
      rescue
        Object.const_set(exception_name.gsub(/:+/, "_"), Class.new(Exception))
      end

      def logger
        nil
      end
    end
    class AirbrakeVerificationController < ApplicationController; end

    puts 'Processing request.'
    request = ActionController::TestRequest.new("REQUEST_URI" => "/airbrake_verification_controller")
    response = ActionController::TestResponse.new
    AirbrakeVerificationController.new.process(request, response)
  end
end

