module Airbrake
  module Sidekiq
    # Filter that ignores classes a minimum number of times before sending to airbrake
    class IgnorableClassFilter
      if Gem::Version.new(::Sidekiq::VERSION) < Gem::Version.new('5.0.0')
        require 'sidekiq/middleware/server/retry_jobs'
        DEFAULT_MAX_RETRY_ATTEMPTS = \
          ::Sidekiq::Middleware::Server::RetryJobs::DEFAULT_MAX_RETRY_ATTEMPTS
      else
        require 'sidekiq/job_retry'
        DEFAULT_MAX_RETRY_ATTEMPTS = ::Sidekiq::JobRetry::DEFAULT_MAX_RETRY_ATTEMPTS
      end

      attr_accessor :retry_attempts_before_airbrake
      attr_accessor :ignorable_classes

      def initialize(retry_attempts_before_airbrake: nil, ignorable_classes: nil)
        @retry_attempts_before_airbrake = [retry_attempts_before_airbrake.to_i, DEFAULT_MAX_RETRY_ATTEMPTS].min
        @ignorable_classes = Array(ignorable_classes)
      end

      def call(notice)
        job = notice[:params][:job]

        notice.ignore! if ignorable?(job)
      end

      private

      def ignorable?(job)
        # DO NOT IGNORE if not a job or does not have a retry
        return false unless job && job['retry']

        # IGNORE if an ignorable class and retry attempts less than RETRY_ATTEMPTS_BEFORE_AIRBRAKE
        if @ignorable_classes.include?(job['class'])
          if job['retry_count'] > @retry_attempts_before_airbrake
            return false
          else
            return true
          end
        end

        # DO NOT IGNORE all the others
        return false
      end
    end
  end
end
