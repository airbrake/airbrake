module Airbrake
  module Sidekiq
    ##
    # Provides integration with Sidekiq 2 and Sidekiq 3.
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
        params = context.merge(component: 'sidekiq', action: context['class'])
        Airbrake.notify(exception, params)
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
