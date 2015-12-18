module Airbrake
  module Rack
    ##
    # Airbrake Rack middleware for Rails and Sinatra applications (or any other
    # Rack-compliant app). Any errors raised by the upstream application will be
    # delivered to Airbrake and re-raised.
    #
    # The middleware automatically sends information about the framework that
    # uses it (name and version).
    class Middleware
      def initialize(app)
        @app = app
      end

      ##
      # Rescues any exceptions, sends them to Airbrake and re-raises the
      # exception.
      # @param [Hash] env the Rack environment
      def call(env)
        # rubocop:disable Lint/RescueException
        begin
          response = @app.call(env)
        rescue Exception => ex
          notify_airbrake(ex, env)
          raise ex
        end
        # rubocop:enable Lint/RescueException

        # The internal framework middlewares store exceptions inside the Rack
        # env. See: https://goo.gl/Kd694n
        exception = env['action_dispatch.exception'] || env['sinatra.error']
        notify_airbrake(exception, env) if exception

        response
      end

      private

      def notify_airbrake(exception, env)
        notice = NoticeBuilder.new(env).build_notice(exception)
        Airbrake.notify(notice)
      end
    end
  end
end
