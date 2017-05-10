module Airbrake
  module Sidekiq
    ##
    # Provides integration with Sidekiq 2, 4, 5.
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
          notice[:context][:action] = context['class']
        end
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
