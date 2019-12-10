require 'airbrake/rails/event'

module Airbrake
  module Rails
    # ActionControllerNotifySubscriber sends route stat information, including
    # performance data.
    #
    # @since v8.0.0
    class ActionControllerNotifySubscriber
      def call(*args)
        routes = Airbrake::Rack::RequestStore[:routes]
        return if !routes || routes.none?

        event = Airbrake::Rails::Event.new(*args)

        routes.each do |route, _params|
          Airbrake.notify_request(
            method: event.method,
            route: route,
            status_code: event.status_code,
            start_time: event.time,
            end_time: Time.new,
          )
        end
      end
    end
  end
end
