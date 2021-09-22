# frozen_string_literal: true

require 'airbrake/rails/railtie'

module Airbrake
  # Rails namespace holds all Rails-related functionality.
  module Rails
    def self.logger
      # Rails.logger is not set in some Rake tasks such as
      # 'airbrake:deploy'. In this case we use a sensible fallback.
      level = (::Rails.logger ? ::Rails.logger.level : Logger::ERROR)

      if ENV['RAILS_LOG_TO_STDOUT'].present?
        Logger.new($stdout, level: level)
      else
        Logger.new(::Rails.root.join('log', 'airbrake.log'), level: level)
      end
    end
  end
end

if defined?(ActionController::Metal)
  require 'airbrake/rails/action_controller'
  module ActionController
    # Adds support for Rails API/Metal for Rails < 5. Rails 5+ uses standard
    # hooks.
    # @see https://github.com/airbrake/airbrake/issues/821
    class Metal
      include Airbrake::Rails::ActionController
    end
  end
end
