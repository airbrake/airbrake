require 'airbrake'
require 'rails'

module Airbrake
  class Railtie < ::Rails::Railtie
    rake_tasks do
      require 'airbrake/rake_handler'
      require "airbrake/rails3_tasks"
    end

    initializer "airbrake.use_rack_middleware" do |app|
      app.config.middleware.insert 0, "Airbrake::UserInformer"
      app.config.middleware.insert_after "Airbrake::UserInformer","Airbrake::Rack"
    end

    config.after_initialize do
      Airbrake.configure(true) do |config|
        config.logger           ||= config.async? ? ::Logger.new(STDERR) : ::Rails.logger
        config.environment_name ||= ::Rails.env
        config.project_root     ||= ::Rails.root
        config.framework        = "Rails: #{::Rails::VERSION::STRING}"
      end

      ActiveSupport.on_load(:action_controller) do
        # Lazily load action_controller methods
        #
        require 'airbrake/rails/javascript_notifier'
        require 'airbrake/rails/controller_methods'

        include Airbrake::Rails::JavascriptNotifier
        include Airbrake::Rails::ControllerMethods
      end

      if defined?(::ActionDispatch::DebugExceptions)
        # We should catch the exceptions in ActionDispatch::DebugExceptions in Rails 3.2.x.
        #
        require 'airbrake/rails/middleware/exceptions_catcher'
        ::ActionDispatch::DebugExceptions.send(:include,Airbrake::Rails::Middleware::ExceptionsCatcher)
      elsif defined?(::ActionDispatch::ShowExceptions)
        # ActionDispatch::DebugExceptions is not defined in Rails 3.0.x and 3.1.x so
        # catch the exceptions in ShowExceptions.
        #
        require 'airbrake/rails/middleware/exceptions_catcher'
        ::ActionDispatch::ShowExceptions.send(:include,Airbrake::Rails::Middleware::ExceptionsCatcher)
      end
    end
  end
end
