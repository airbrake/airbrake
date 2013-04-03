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
        begin
          response = @app.call(env)
        rescue Exception => exception
          env['airbrake.error_id'] = notify_airbrake(env, exception)
          raise exception
        end

        if framework_exception = env["action_dispatch.exception"]
          env["airbrake.error_id"] = notify_airbrake(env, framework_exception)
        end

        response
      end

      private

      def after_airbrake_handler(env, exception)
        if defined? env["action_controller.instance"].
          rescue_action_in_public_without_airbrake

          env["action_controller.instance"].
            rescue_action_in_public_without_airbrake(exception)
        end
      end

      def notify_airbrake(env, exception)
        unless ignored_user_agent? env
          error_id = Airbrake.notify_or_ignore(exception, request_data(env))
          after_airbrake_handler(env, exception)
          error_id
        end
      end

      def request_data(env)
        env["action_controller.instance"].try(:airbrake_request_data) ||
          {:rack_env => env}
      end

      def ignored_user_agent?(env)
        true if Airbrake.
          configuration.
          ignore_user_agent.
          flatten.
          any? { |ua| ua === env['HTTP_USER_AGENT'] }
      end
    end
  end
end
