module Airbrake
  module Rails
    # Rack middleware for Rails applications. Any errors raised by the upstream
    # application will be delivered to Airbrake and re-raised.
    #
    class Middleware < Airbrake::Rack

      protected

      def after_airbrake_handler(env, exception)
        if defined? env["action_controller.instance"].
          rescue_action_in_public_without_airbrake

          env["action_controller.instance"].
            rescue_action_in_public_without_airbrake(exception)
        end
      end

      def request_data(env)
        env["action_controller.instance"].try(:airbrake_request_data) || super
      end

      def framework_exception(env)
        env["action_dispatch.exception"]
      end
    end
  end
end
