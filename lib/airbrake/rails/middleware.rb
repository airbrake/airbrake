module Airbrake
  module Rails
    # Rack middleware for Rails applications. Any errors raised by the upstream
    # application will be delivered to Airbrake and re-raised.
    #
    class Middleware
      def initialize(app)
        @app = app
      end

      def call(env)
        @env = env

        begin
          response = @app.call(@env)
        rescue Exception => exception
          @env['airbrake.error_id'] = notify_airbrake(exception)
          raise exception
        end

        if framework_exception
          @env["airbrake.error_id"] = notify_airbrake(framework_exception)
        end

        response
      end

      private

      def controller
        @env["action_controller.instance"]
      end

      def after_airbrake_handler(exception)
        if defined?(controller.rescue_action_in_public_without_airbrake)
          controller.rescue_action_in_public_without_airbrake(exception)
        end
      end

      def notify_airbrake(exception)
        unless ignored_user_agent?
          error_id = Airbrake.notify_or_ignore(exception, request_data)
          after_airbrake_handler(exception)
          error_id
        end
      end

      def request_data
        controller.try(:airbrake_request_data) || {:rack_env => @env}
      end

      def ignored_user_agent?
        true if Airbrake.
          configuration.
          ignore_user_agent.
          flatten.
          any? { |ua| ua === @env['HTTP_USER_AGENT'] }
      end

      def framework_exception
        @env["action_dispatch.exception"]
      end
    end
  end
end
