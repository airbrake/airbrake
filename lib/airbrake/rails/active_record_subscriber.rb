module Airbrake
  module Rails
    # ActiveRecordSubscriber sends SQL information, including performance data.
    #
    # @since v8.1.0
    class ActiveRecordSubscriber
      def initialize(notifier)
        @notifier = notifier
      end

      def call(*args)
        event = ActiveSupport::Notifications::Event.new(*args)
        @notifier.notify(
          Airbrake::Query.new(
            route: Thread.current[:airbrake_rails_route],
            method: Thread.current[:airbrake_rails_method],
            query: event.payload[:sql],
            start_time: event.time,
            end_time: event.end
          )
        )
      end
    end
  end
end
