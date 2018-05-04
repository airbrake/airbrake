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
        klass = payload['class'].to_s
        return klass unless payload['args'] && payload['args'].first
        return klass unless (job_class = payload['args'].first['job_class'])
        job_class
      end
    end
  end
end
