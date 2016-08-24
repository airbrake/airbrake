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

      rails_4_or_less = ::Rails::VERSION::MAJOR < 5

      middleware = if defined?(ActionDispatch::DebugExceptions)
        # Rails >= 3.2.0
        rails_4_or_less ? "ActionDispatch::DebugExceptions" : ActionDispatch::DebugExceptions
      else
        # Rails < 3.2.0
        "ActionDispatch::ShowExceptions"
      end

      app.config.middleware.insert_after middleware, (rails_4_or_less ? "Airbrake::Rails::Middleware" : Airbrake::Rails::Middleware)

      app.config.middleware.insert 0, (rails_4_or_less ? "Airbrake::UserInformer" : Airbrake::UserInformer)
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
