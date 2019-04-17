require 'airbrake/rails/event'
require 'airbrake/rails/app'

module Airbrake
  module Rails
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
        route = find_route(event.params)
        return unless route

        routes[route.path] = {
          method: event.method,
          response_type: event.response_type,
          groups: {}
        }
      end

      private

      def find_route(params)
        @app.routes.find do |route|
          route.controller == params['controller'] &&
            route.action == params['action']
        end
      end
    end
  end
end
