module Airbrake
  module Rails
    # ActionControllerNotifySubscriber sends route stat information, including
    # performance data.
    #
    # @since v8.0.0
    class ActionControllerNotifySubscriber
      def initialize(notifier, routes)
        @notifier = notifier
        @routes = routes
      end

      def call(*args)
        return if @routes.none?

        event = ActiveSupport::Notifications::Event.new(*args)
        payload = event.payload

        @routes.each do |route, method|
          @notifier.notify(
            Airbrake::Request.new(
              method: method,
              route: route,
              status_code: find_status_code(payload),
              start_time: event.time,
              end_time: Time.new
            )
          )
        end
      end

      private

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
