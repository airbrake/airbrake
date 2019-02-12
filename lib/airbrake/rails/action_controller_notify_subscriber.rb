module Airbrake
  module Rails
    # ActionControllerNotifySubscriber sends route stat information, including
    # performance data.
    #
    # @since v8.0.0
    class ActionControllerNotifySubscriber
      def initialize(notifier)
        @notifier = notifier
      end

      def call(*args)
        return unless (route = Thread.current[:airbrake_rails_route])

        event = ActiveSupport::Notifications::Event.new(*args)
        payload = event.payload

        @notifier.notify(
          Airbrake::Request.new(
            method: payload[:method],
            route: route,
            status_code: find_status_code(payload),
            start_time: event.time,
            end_time: Time.new
          )
        )
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
