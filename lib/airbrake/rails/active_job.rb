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

        Airbrake.notify(exception) do |notice|
          notice[:context][:component] = 'active_job'
          notice[:context][:action] = job.class.name
          notice[:params].merge!(job.serialize)
        end

        raise exception
      end

      included do
        rescue_from(Exception) do |exception|
          Airbrake::Rails::ActiveJob.notify_airbrake(exception, self)
        end
      end
    end
  end
end
