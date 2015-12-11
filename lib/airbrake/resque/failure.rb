module Resque
  module Failure
    ##
    # Provides Resque integration with Airbrake.
    #
    # @since v5.0.0
    # @see https://github.com/resque/resque/wiki/Failure-Backends
    class Airbrake < Base
      def save
        params = payload.merge(
          component: 'resque',
          action: payload['class'].to_s
        )

        ::Airbrake.notify_sync(exception, params)
      end
    end
  end
end
