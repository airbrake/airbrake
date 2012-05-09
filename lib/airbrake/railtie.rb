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
        config.logger           ||= ::Rails.logger
        config.environment_name ||= ::Rails.env
        config.project_root     ||= ::Rails.root
        config.framework        = "Rails: #{::Rails::VERSION::STRING}"
      end

      ActiveSupport.on_load(:action_controller) do
        require 'airbrake/rails/javascript_notifier'
        require 'airbrake/rails/controller_methods'

        include Airbrake::Rails::JavascriptNotifier
        include Airbrake::Rails::ControllerMethods
      end

      if defined?(::ActionDispatch::DebugExceptions)
        require 'airbrake/rails/middleware/debug_exceptions_catcher'
        ::ActionDispatch::DebugExceptions.send(:include,Airbrake::Rails::Middleware::DebugExceptionsCatcher)
      end
    end
  end
end
