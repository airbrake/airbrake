module Airbrake
  module Rails
    ##
    # Contains helper methods that can be used inside Rails controllers to send
    # notices to Airbrake. The main benefit of using them instead of the direct
    # API is that they automatically add information from the Rack environment
    # to notices.
    module ActionController
      private

      ##
      # A helper method for sending notices to Airbrake *asynchronously*.
      # Attaches information from the Rack env.
      # @see Airbrake#notify, #notify_airbrake_sync
      def notify_airbrake(exception, parameters = {}, notifier = :default)
        Airbrake.notify(build_notice(exception), parameters, notifier)
      end

      ##
      # A helper method for sending notices to Airbrake *synchronously*.
      # Attaches information from the Rack env.
      # @see Airbrake#notify_sync, #notify_airbrake
      def notify_airbrake_sync(exception, parameters = {}, notifier = :default)
        Airbrake.notify_sync(build_notice(exception), parameters, notifier)
      end

      ##
      # @param [Exception] exception
      # @return [Airbrake::Notice] the notice with information from the Rack env
      def build_notice(exception)
        Airbrake::Rack::NoticeBuilder.new(request.env).build_notice(exception)
      end
    end
  end
end
