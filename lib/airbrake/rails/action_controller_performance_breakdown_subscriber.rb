module Airbrake
  module Rails
    # @since v8.3.0
    class ActionControllerPerformanceBreakdownSubscriber
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
            response_type: payload[:format],
            groups: groups,
            start_time: event.time
          )
        end
      end

      private

      def build_groups(payload)
        groups = %i[db_runtime view_runtime].map do |metric|
          ms = payload[metric] || 0
          next if ms == 0

          [metric.to_s.split('_').first, ms]
        end
        groups.compact.to_h
      end
    end
  end
end
