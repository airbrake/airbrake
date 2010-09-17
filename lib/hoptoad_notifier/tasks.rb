require 'hoptoad_notifier'

namespace :hoptoad do
  desc "Notify Hoptoad of a new deploy."
  task :deploy => :environment do
    require 'hoptoad_tasks'
    HoptoadTasks.deploy(:rails_env      => ENV['TO'], 
                        :scm_revision   => ENV['REVISION'],
                        :scm_repository => ENV['REPO'],
                        :local_username => ENV['USER'],
                        :api_key        => ENV['API_KEY'])
  end

  task :log_stdout do
    require 'logger'
    RAILS_DEFAULT_LOGGER = Logger.new(STDOUT)
  end

  desc "Verify your gem installation by sending a test exception to the hoptoad service"
  task :test => ['hoptoad:log_stdout', :environment] do
    RAILS_DEFAULT_LOGGER.level = Logger::DEBUG

    require 'action_controller/test_process'

    Dir["app/controllers/application*.rb"].each { |file| require(file) }

    class HoptoadTestingException < RuntimeError; end

    unless HoptoadNotifier.configuration.api_key
      puts "Hoptoad needs an API key configured! Check the README to see how to add it."
      exit
    end

    HoptoadNotifier.configuration.development_environments = []

    catcher = HoptoadNotifier::Rails::ActionControllerCatcher
    in_controller = ApplicationController.included_modules.include?(catcher)
    in_base = ActionController::Base.included_modules.include?(catcher)
    if !in_controller || !in_base
      puts "Rails initialization did not occur"
      exit
    end

    puts "Configuration:"
    HoptoadNotifier.configuration.to_hash.each do |key, value|
      puts sprintf("%25s: %s", key.to_s, value.inspect.slice(0, 55))
    end

    unless defined?(ApplicationController)
      puts "No ApplicationController found"
      exit
    end

    puts 'Setting up the Controller.'
    class ApplicationController
      # This is to bypass any filters that may prevent access to the action.
      prepend_before_filter :test_hoptoad
      def test_hoptoad
        puts "Raising '#{exception_class.name}' to simulate application failure."
        raise exception_class.new, 'Testing hoptoad via "rake hoptoad:test". If you can see this, it works.'
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
        exception_name = ENV['EXCEPTION'] || "HoptoadTestingException"
        Object.const_get(exception_name)
      rescue
        Object.const_set(exception_name, Class.new(Exception))
      end

      def logger
        nil
      end
    end
    class HoptoadVerificationController < ApplicationController; end

    puts 'Processing request.'
    request = ActionController::TestRequest.new("REQUEST_URI" => "/hoptoad_verification_controller")
    response = ActionController::TestResponse.new
    HoptoadVerificationController.new.process(request, response)
  end
end

