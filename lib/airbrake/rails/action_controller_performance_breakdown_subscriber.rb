require 'airbrake/rails/event'

module Airbrake
  module Rails
    # @since v8.3.0
    class ActionControllerPerformanceBreakdownSubscriber
      def call(*args)
        routes = Airbrake::Rack::RequestStore[:routes]
        return if !routes || routes.none?

        event = Airbrake::Rails::Event.new(*args)

        routes.each do |route, params|
          groups = event.groups.merge(params[:groups])
          next if groups.none?

          Airbrake.notify_performance_breakdown(
            method: event.method,
            route: route,
            response_type: event.response_type,
            groups: groups,
            start_time: event.time
          )
        end
      end
    end
  end
end
