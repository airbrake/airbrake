module Airbrake
  module Rails
    # ActionControllerRouteSubscriber sends route stat information, including
    # performance data.
    #
    # @since v8.0.0
    class ActionControllerRouteSubscriber
      def initialize
        @all_routes = nil
      end

      def call(*args)
        # We cannot move this to #initialize because Rails initializes routes
        # after hooks.
        @all_routes ||= find_all_routes

        event = ActiveSupport::Notifications::Event.new(*args)
        payload = event.payload

        Thread.current[:airbrake_rails_route] = find_route(payload[:params])
        Thread.current[:airbrake_rails_method] = payload[:method]
      end

      private

      def find_route(params)
        @all_routes.each do |r|
          if r.defaults[:controller] == params['controller'] &&
             r.defaults[:action] == params['action']
            return r.path.spec.to_s
          end
        end
      end

      # Finds all routes that the app supports, including engines.
      def find_all_routes
        routes = [*::Rails.application.routes.routes.routes]
        ::Rails::Engine.subclasses.each do |engine|
          routes.push(*engine.routes.routes.routes)
        end
        routes
      end
    end
  end
end
