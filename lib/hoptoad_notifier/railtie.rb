require 'hoptoad_notifier'
require 'rails'

module HoptoadNotifier
  class Railtie < Rails::Railtie
    railtie_name :hoptoad_notifier

    rake_tasks do
      require "hoptoad_notifier/rails3_tasks"
    end

    config.middleware.insert_after ActionDispatch::ShowExceptions, HoptoadNotifier::Rack

    config.after_initialize do
      HoptoadNotifier.configure(true) do |config|
        config.logger           = Rails.logger
        # config.environment_name = Rails.env
        # config.project_root     = Rails.root
        config.framework        = "Rails: #{::Rails::VERSION::STRING}"
      end
    end
  end
end
