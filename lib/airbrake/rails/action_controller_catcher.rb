module Airbrake
  module Rails
    module ActionControllerCatcher

      # Sets up an alias chain to catch exceptions for Rails 2
      def self.included(base) #:nodoc:
        if base.method_defined?(:rescue_action_in_public)
          base.send(:alias_method, :rescue_action_in_public_without_airbrake, :rescue_action_in_public)
          base.send(:alias_method, :rescue_action_in_public, :rescue_action_in_public_with_airbrake)
        end
      end

      private

      # Overrides the rescue_action method in ActionController::Base, but does not inhibit
      # any custom processing that is defined with Rails 2's exception helpers.
      def rescue_action_in_public_with_airbrake(exception)
        unless airbrake_ignore_user_agent?
          error_id = Airbrake.notify_or_ignore(exception, airbrake_request_data)
          request.env['airbrake.error_id'] = error_id
        end
        rescue_action_in_public_without_airbrake(exception)
      end

      def airbrake_ignore_user_agent? #:nodoc:
        # Rails 1.2.6 doesn't have request.user_agent, so check for it here
        user_agent = request.respond_to?(:user_agent) ? request.user_agent : request.env["HTTP_USER_AGENT"]
        Airbrake.configuration.ignore_user_agent.flatten.any? { |ua| ua === user_agent }
      end
    end
  end
end
