namespace :hoptoad do
  desc "Verify your plugin installation by sending a test exception to the hoptoad service"
  task :test => :environment do
    require 'action_controller/test_process'
    require 'application'

    request = ActionController::TestRequest.new({
      'action'     => 'verify',
      'controller' => 'hoptoad_verification',
      '_method'    => 'GET'
    })

    response = ActionController::TestResponse.new

    class HoptoadTestingException < RuntimeError; end

    puts 'Setting up the Controller.'
    class ApplicationController
      # This is to bypass any filters that may prevent access to the action.
      prepend_before_filter :test_hoptoad
      def test_hoptoad
        puts "Raising '#{exception_class.name}' to simulate application failure."
        raise exception_class.new, 'Testing hoptoad via "rake hoptoad:test". If you can see this, it works.'
      end

      def rescue_action exception
        rescue_action_in_public exception
      end

      def public_environment?
        true
      end

      # Ensure we actually have an action to go to.
      def verify; end

      def exception_class
        exception_name = ENV['EXCEPTION'] || "HoptoadTestingException"
        Object.const_get(exception_name)
      rescue
        Object.const_set(exception_name, Class.new(Exception))
      end
    end

    puts 'Processing request.'
    class HoptoadVerificationController < ApplicationController; end
    HoptoadVerificationController.new.process(request, response)
  end
end

