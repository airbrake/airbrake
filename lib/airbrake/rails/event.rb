module Airbrake
  module Rails
    # Event is a wrapper around ActiveSupport::Notifications::Event.
    #
    # @since v9.0.3
    # @api private
    class Event
      def initialize(*args)
        @event = ActiveSupport::Notifications::Event.new(*args)
      end

      def method
        @event.payload[:method]
      end

      def format
        @event.payload[:format]
      end

      def params
        @event.payload[:params]
      end
    end
  end
end
