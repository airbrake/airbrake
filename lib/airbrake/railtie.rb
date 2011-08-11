require 'airbrake'
require 'rails'

module Airbrake
  class Railtie < Rails::Railtie
    rake_tasks do
      require 'airbrake/rake_handler'
      require "airbrake/rails3_tasks"
    end

    initializer "airbrake.use_rack_middleware" do |app|
      app.config.middleware.use "Airbrake::Rack"
      app.config.middleware.insert 0, "Airbrake::UserInformer"
    end

    config.after_initialize do
      Airbrake.configure(true) do |config|
        config.logger           ||= Rails.logger
        config.environment_name ||= Rails.env
        config.project_root     ||= Rails.root
        config.framework        = "Rails: #{::Rails::VERSION::STRING}"
      end

      if defined?(::ActionController::Base)
        require 'airbrake/rails/javascript_notifier'
        require 'airbrake/rails/controller_methods'

        ::ActionController::Base.send(:include, Airbrake::Rails::ControllerMethods)
        ::ActionController::Base.send(:include, Airbrake::Rails::JavascriptNotifier)
      end
    end
  end
end
