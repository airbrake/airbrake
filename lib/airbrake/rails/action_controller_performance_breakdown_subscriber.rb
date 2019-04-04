module Airbrake
  module Rails
    # @since v8.3.0
    class ActionControllerPerformanceBreakdownSubscriber
      # @see https://github.com/rails/rails/issues/8987
      HTML_RESPONSE_WILDCARD = "*/*".freeze

      def call(*args)
        routes = Airbrake::Rack::RequestStore[:routes]
        return if !routes || routes.none?

        event = ActiveSupport::Notifications::Event.new(*args)
        payload = event.payload

        routes.each do |route, method|
          next if (groups = build_groups(payload)).none?

          Airbrake.notify_performance_breakdown(
            method: method,
            route: route,
            response_type: normalize_response_type(payload[:format]),
            groups: groups,
            start_time: event.time
          )
        end
      end

      private

      def build_groups(payload)
        groups = {}

        db_runtime = payload[:db_runtime] || 0
        groups[:db] = db_runtime if db_runtime > 0

        view_runtime = payload[:view_runtime] || 0
        groups[:view] = view_runtime if view_runtime > 0

        groups
      end

      def normalize_response_type(response_type)
        response_type == HTML_RESPONSE_WILDCARD ? :html : response_type
      end
    end
  end
end
