module Resque
  module Failure
    ##
    # Provides Resque integration with Airbrake.
    #
    # @since v5.0.0
    # @see https://github.com/resque/resque/wiki/Failure-Backends
    class Airbrake < Base
      def save
        return if activejob_exception?
        params = payload.merge(
          component: 'resque',
          action: payload['class'].to_s
        )

        ::Airbrake.notify_sync(exception, params)
      end

      # AirBrake gem already attaches error notifications to ActiveJob
      # so it needs to be skipped or duplicate exception will be logged
      def activejob_exception?
        payload['class'].to_s == 'ActiveJob::QueueAdapters::ResqueAdapter::JobWrapper'
      end
    end
  end
end
