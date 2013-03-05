require 'rails'

module Airbrake
  class Engine < ::Rails::Engine

    if Rails.version >= '3.1'
      initializer :assets do |config|
        Rails.application.config.assets.precompile << "airbrake-notifier.js"
      end
    end
  end
end
