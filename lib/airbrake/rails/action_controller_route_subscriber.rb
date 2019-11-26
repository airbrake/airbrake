require 'airbrake/rails/event'
require 'airbrake/rails/app'

module Airbrake
  module Rails
    # ActionControllerRouteSubscriber sends route stat information, including
    # performance data.
    #
    # @since v8.0.0
    class ActionControllerRouteSubscriber
      def call(*args)
        # We don't track routeless events.
        return unless (routes = Airbrake::Rack::RequestStore[:routes])

        event = Airbrake::Rails::Event.new(*args)
        route = Airbrake::Rails::App.recognize_route(
          Airbrake::Rack::RequestStore[:request]
        )
        return unless route

        routes[find_route_name(route)] = {
          method: event.method,
          response_type: event.response_type,
          groups: {}
        }
      end

      def find_route_name(route)
        if route.app.respond_to?(:app) && route.app.app.respond_to?(:engine_name)
          "#{route.app.app.engine_name}##{route.path.spec}"
        else
          route.path.spec.to_s
        end
      end
    end
  end
end
