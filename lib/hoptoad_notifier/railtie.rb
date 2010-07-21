require 'hoptoad_notifier'
require 'rails'

module HoptoadNotifier
  class Railtie < Rails::Railtie
    rake_tasks do
      require "hoptoad_notifier/rails3_tasks"
    end

    initializer "hoptoad.use_rack_middleware" do |app|
      app.config.middleware.use "HoptoadNotifier::Rack"
    end

    config.after_initialize do
      HoptoadNotifier.configure(true) do |config|
        config.logger           = Rails.logger
        config.environment_name = Rails.env
        config.project_root     = Rails.root
        config.framework        = "Rails: #{::Rails::VERSION::STRING}"
      end

      if defined?(::ActionController::Base)
        require 'hoptoad_notifier/rails/javascript_notifier'

        ::ActionController::Base.send(:include, HoptoadNotifier::Rails::JavascriptNotifier)
      end
    end
  end
end
