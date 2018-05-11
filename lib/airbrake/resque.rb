module Resque
  module Failure
    # Provides Resque integration with Airbrake.
    #
    # @since v5.0.0
    # @see https://github.com/resque/resque/wiki/Failure-Backends
    class Airbrake < Base
      def save
        ::Airbrake.notify_sync(exception, payload) do |notice|
          notice[:context][:component] = 'resque'
          notice[:context][:action] = action(payload)
        end
      end

      private

      # @return [String] job's name. When ActiveJob is present, retrieve
      #   job_class. When used directly, use worker's name
      def action(payload)
        active_job_args = payload['args'].first if payload['args']
        if active_job_args.is_a?(Hash) && active_job_args['job_class']
          active_job_args['job_class']
        else
          payload['class'].to_s
        end
      end
    end
  end
end
