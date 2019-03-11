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
          Airbrake.notify_performance_breakdown(
            method: method,
            route: route,
            response_type: payload[:format],
            groups: {
              db: payload[:db_runtime].to_i,
              view: payload[:view_runtime].to_i
            },
            start_time: event.time
          )
        end
      end
    end
  end
end
