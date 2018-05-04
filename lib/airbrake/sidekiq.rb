require 'airbrake/sidekiq/retryable_jobs_filter'

module Airbrake
  module Sidekiq
    # Provides integration with Sidekiq v2+.
    class ErrorHandler
      # rubocop:disable Lint/RescueException
      def call(_worker, context, _queue)
        yield
      rescue Exception => exception
        notify_airbrake(exception, context)
        raise exception
      end
      # rubocop:enable Lint/RescueException

      private

      def notify_airbrake(exception, context)
        Airbrake.notify(exception, context) do |notice|
          notice[:context][:component] = 'sidekiq'
          notice[:context][:action] = action(context)
        end
      end

      # @return [String] job's name. When ActiveJob is present, retrieve
      #   job_class. When used directly, use worker's name
      def action(context)
        klass = context['class'] || context[:job] && context[:job]['class']
        return klass unless context[:job] && context[:job]['args'].first.is_a?(Hash)
        return klass unless (job_class = context[:job]['args'].first['job_class'])
        job_class
      end
    end
  end
end

if Sidekiq::VERSION < '3'
  Sidekiq.configure_server do |config|
    config.server_middleware do |chain|
      chain.add(Airbrake::Sidekiq::ErrorHandler)
    end
  end
else
  Sidekiq.configure_server do |config|
    config.error_handlers << Airbrake::Sidekiq::ErrorHandler.new.method(:notify_airbrake)
  end
end
