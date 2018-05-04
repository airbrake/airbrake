module Airbrake
  module Shoryuken
    # Provides integration with Shoryuken.
    class ErrorHandler
      # rubocop:disable Lint/RescueException
      def call(worker, queue, _sqs_msg, body)
        yield
      rescue Exception => exception
        notify_airbrake(exception, worker, queue, body)

        raise exception
      end
      # rubocop:enable Lint/RescueException

      private

      def notify_airbrake(exception, worker, queue, body)
        Airbrake.notify(exception, notice_context(queue, body)) do |notice|
          notice[:context][:component] = 'shoryuken'
          notice[:context][:action] = worker.class.to_s
        end
      end

      def notice_context(queue, body)
        {
          queue: queue,
          body: body.is_a?(Array) ? { batch: body } : { body: body }
        }
      end
    end
  end
end

if defined?(::Shoryuken)
  Shoryuken.configure_server do |config|
    config.server_middleware do |chain|
      chain.add Airbrake::Shoryuken::ErrorHandler
    end
  end
end
