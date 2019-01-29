module Airbrake
  module Rails
    # ActionControllerRouteSubscriber sends route stat information, including
    # performance data.
    #
    # @since v8.0.0
    class ActionControllerRouteSubscriber
      def initialize(notifier)
        @notifier = notifier
        @all_routes = nil
      end

      def call(*args)
        # We cannot move this to #initialize because Rails initializes routes
        # after hooks.
        @all_routes ||= find_all_routes

        event = ActiveSupport::Notifications::Event.new(*args)
        payload = event.payload

        return unless (route = find_route(payload[:params]))
        @notifier.notify_request(
          method: payload[:method],
          route: route,
          status_code: find_status_code(payload),
          start_time: event.time,
          end_time: Time.new
        )
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

      def find_status_code(payload)
        return payload[:status] if payload[:status]

        if payload[:exception]
          status = ActionDispatch::ExceptionWrapper.status_code_for_exception(
            payload[:exception].first
          )
          status = 500 if status == 0

          return status
        end

        0
      end
    end
  end
end
