# frozen_string_literal: true

module Airbrake
  module Rails
    # Enables support for exceptions occurring in ActiveJob jobs.
    module ActiveJob
      extend ActiveSupport::Concern

      # @return [Array<Regexp>] the list of known adapters
      ADAPTERS = [/Resque/, /Sidekiq/, /DelayedJob/].freeze

      def self.notify_airbrake(exception, job)
        queue_adapter = job.class.queue_adapter.to_s

        # Do not notify twice if a queue_adapter is configured already.
        raise exception if ADAPTERS.any? { |a| a =~ queue_adapter }

        notice = Airbrake.build_notice(exception)
        notice[:context][:component] = 'active_job'
        notice[:context][:action] = job.class.name
        notice[:params].merge!(job.serialize)

        Airbrake.notify(notice)

        raise exception
      end

      def self.perform(job, block)
        timing = Airbrake::Benchmark.measure do
          block.call
        end
      rescue StandardError => exception
        Airbrake.notify_queue_sync(
          queue: job.class.name,
          error_count: 1,
          timing: 0.01,
        )
        raise exception
      else
        Airbrake.notify_queue_sync(
          queue: job.class.name,
          error_count: 0,
          timing: timing,
        )
      end

      included do
        rescue_from(Exception) do |exception|
          Airbrake::Rails::ActiveJob.notify_airbrake(exception, self)
        end

        around_perform do |job, block|
          Airbrake::Rails::ActiveJob.perform(job, block)
        end
      end
    end
  end
end
