# frozen_string_literal: true

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

module Airbrake
  module Resque
    # Measures elapsed time of a job and notifies Airbrake of the execution
    # status.
    #
    # @since v9.6.0
    module Job
      def perform
        timing = Airbrake::Benchmark.measure do
          super
        end
      rescue StandardError => exception
        Airbrake.notify_queue_sync(
          queue: payload['class'],
          error_count: 1,
          timing: 0.01,
        )
        raise exception
      else
        Airbrake.notify_queue_sync(
          queue: payload['class'],
          error_count: 0,
          timing: timing,
        )
      end
    end
  end
end

Resque::Job.prepend(Airbrake::Resque::Job)
