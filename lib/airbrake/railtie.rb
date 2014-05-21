require 'airbrake'
require 'rails'

require 'airbrake/rails/middleware'

module Airbrake
  class Railtie < ::Rails::Railtie
    rake_tasks do
      require 'airbrake/rake_handler'
      require 'airbrake/rails3_tasks'
    end

    initializer "airbrake.middleware" do |app|

      middleware = if defined?(ActionDispatch::DebugExceptions)
        # Rails >= 3.2.0
        "ActionDispatch::DebugExceptions"
      else
        # Rails < 3.2.0
        "ActionDispatch::ShowExceptions"
      end

      app.config.middleware.insert_after middleware,
        "Airbrake::Rails::Middleware"

      app.config.middleware.insert 0, "Airbrake::UserInformer"
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
        require 'airbrake/rails/controller_methods'

        include Airbrake::Rails::ControllerMethods
      end
    end
  end
end
