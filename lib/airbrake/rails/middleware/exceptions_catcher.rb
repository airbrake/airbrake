module Airbrake
  module Rails
    module Middleware
      module ExceptionsCatcher
        def self.included(base)
          base.send(:alias_method_chain,:render_exception,:airbrake)
        end

        def skip_user_agent?(env)
          user_agent = env["HTTP_USER_AGENT"]
          ::Airbrake.configuration.ignore_user_agent.flatten.any? { |ua| ua === user_agent }
        rescue
          false
        end

        def render_exception_with_airbrake(env,exception)
          begin
            controller = env['action_controller.instance']
            env['airbrake.error_id'] = Airbrake.
              notify_or_ignore(exception,
                               controller.try(:airbrake_request_data) || {:rack_env => env}) unless skip_user_agent?(env)
            if defined?(controller.rescue_action_in_public_without_airbrake)
              controller.rescue_action_in_public_without_airbrake(exception)
            end
          rescue
            # do nothing
          end
          render_exception_without_airbrake(env,exception)
        end
      end
    end
  end
end
