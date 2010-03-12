rails3 = defined?(ActiveSupport::Notifications)

require 'hoptoad_notifier'
require 'hoptoad_notifier/rails/controller_methods'
unless rails3
  require 'hoptoad_notifier/rails/action_controller_catcher'
end
require 'hoptoad_notifier/rails/error_lookup'

module HoptoadNotifier
  module Rails
    def self.initialize
      if defined?(ActiveSupport::Notifications)
        ActiveSupport::Notifications.subscribe "action_dispatch.show_exception" do |*args|
          p args

          payload = args.last

          env = payload[:env]
          exception = payload[:exception]
          request = Rack::Request.new(env)

          hoptoad_request_data = {
              :parameters       => request.params,
              :session_data     => env["rack.session"].to_hash,
              # :controller       => params[:controller],
              # :action           => params[:action],
              :url              => request.url,
              :cgi_data         => env
          }

          HoptoadNotifier.notify(exception, hoptoad_request_data)
        end
      elsif defined?(ActionController::Base)
        ActionController::Base.send(:include, HoptoadNotifier::Rails::ActionControllerCatcher)
        ActionController::Base.send(:include, HoptoadNotifier::Rails::ErrorLookup)
        ActionController::Base.send(:include, HoptoadNotifier::Rails::ControllerMethods)
      end

      rails_logger = if defined?(::Rails.logger)
                       ::Rails.logger
                     elsif defined?(RAILS_DEFAULT_LOGGER)
                       RAILS_DEFAULT_LOGGER
                     end

      rails3 = defined?(ActiveSupport::Notifications)
      unless rails3
        if defined?(::Rails.configuration) && ::Rails.configuration.respond_to?(:middleware)
          ::Rails.configuration.middleware.insert_after 'ActionController::Failsafe',
                                                        HoptoadNotifier::Rack
        end
      end

      HoptoadNotifier.configure(true) do |config|
        config.logger = rails_logger
        config.environment_name = RAILS_ENV  if defined?(RAILS_ENV)
        config.project_root     = RAILS_ROOT if defined?(RAILS_ROOT)
        config.framework        = "Rails: #{::Rails::VERSION::STRING}" if defined?(::Rails::VERSION)
      end
    end
  end
end

HoptoadNotifier::Rails.initialize

