module Airbrake
  module Shoryuken
    ##
    # Provides integration with Shoryuken.
    class ErrorHandler
      def call(_worker, _queue, _sqs_msg, body)
        yield
      rescue => e
        notify_airbrake(e, notice_context(body))
        raise e
      end

      private

      def notice_context(body)
        body.is_a?(Array) ? { batch: body } : { body: body }
      end

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
