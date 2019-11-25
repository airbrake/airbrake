require 'airbrake/rails/event'
require 'airbrake/rails/app'

module Airbrake
  module Rails
    # @return [String]
    CONTROLLER_KEY = 'controller'.freeze

    # @return [String]
    ACTION_KEY = 'action'.freeze

    # ActionControllerRouteSubscriber sends route stat information, including
    # performance data.
    #
    # @since v8.0.0
    class ActionControllerRouteSubscriber
      def initialize
        @app = Airbrake::Rails::App.new
      end

      def call(*args)
        # We don't track routeless events.
        return unless (routes = Airbrake::Rack::RequestStore[:routes])

        event = Airbrake::Rails::Event.new(*args)
        route = Airbrake::Rails::App.recognize_route(
          Airbrake::Rack::RequestStore[:request]
        )
        return unless route

        routes[route] = {
          method: event.method,
          response_type: event.response_type,
          groups: {}
        }
      end
    end
  end
end
