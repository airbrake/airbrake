require 'hoptoad_notifier'
require 'rails'

module HoptoadNotifier
  class Railtie < Rails::Railtie
    railtie_name :hoptoad_notifier

    rake_tasks do
      require "hoptoad_notifier/rails3_tasks"
    end

    config.middleware.insert_after ActionDispatch::ShowExceptions, HoptoadNotifier::Rack
  end
end
