module Airbrake
  module Shoryuken
    class ErrorHandler
      def call(worker, queue, sqs_msg, body)
        begin
          yield
        rescue => e
          notify_airbrake(e, body.is_a?(Array) ? { batch: body } : body)
          raise e
        end
      end

      private

      def notify_airbrake(exception, context)
        return unless (notice = Airbrake.build_notice(exception, context))

        Airbrake.notify(notice)
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
