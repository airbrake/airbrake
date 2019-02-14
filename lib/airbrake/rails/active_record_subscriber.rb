module Airbrake
  module Rails
    # ActiveRecordSubscriber sends SQL information, including performance data.
    #
    # @since v8.1.0
    class ActiveRecordSubscriber
      def initialize(notifier, routes)
        @notifier = notifier
        @routes = routes
      end

      def call(*args)
        event = ActiveSupport::Notifications::Event.new(*args)
        @routes.each do |route, method|
          @notifier.notify(
            Airbrake::Query.new(
              route: route,
              method: method,
              query: event.payload[:sql],
              start_time: event.time,
              end_time: event.end
            )
          )
        end
      end
    end
  end
end
