require 'better_errors'

module BetterErrors
  class Middleware
    alias_method :show_error_page_original, :show_error_page

    private

    def show_error_page(env, exception=nil)
      env['airbrake.error_id'] = notify_airbrake(env, exception)
      show_error_page_original(env, exception)
    end

    def notify_airbrake(env, exception)
      unless ignored_user_agent? env
        Airbrake.notify_or_ignore(exception, request_data(env))
      end
    end

    def ignored_user_agent?(env)
      true if Airbrake.configuration
        .ignore_user_agent.flatten
        .any? { |ua| ua === env['HTTP_USER_AGENT'] }
    end

    def request_data(env)
      if controller(env).respond_to?(:airbrake_request_data)
        controller(env).airbrake_request_data
      else
        {:rack_env => env}
      end
    end

    def controller(env)
      env["action_controller.instance"]
    end
  end
end
