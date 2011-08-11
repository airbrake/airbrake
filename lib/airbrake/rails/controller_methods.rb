module Airbrake
  module Rails
    module ControllerMethods
      private

      # This method should be used for sending manual notifications while you are still
      # inside the controller. Otherwise it works like Airbrake.notify.
      def notify_airbrake(hash_or_exception)
        unless airbrake_local_request?
          Airbrake.notify(hash_or_exception, airbrake_request_data)
        end
      end
      
      def airbrake_local_request?
        if defined?(::Rails.application.config)
          ::Rails.application.config.consider_all_requests_local || request.local?
        else
          consider_all_requests_local || local_request?
        end
      end

      def airbrake_ignore_user_agent? #:nodoc:
        # Rails 1.2.6 doesn't have request.user_agent, so check for it here
        user_agent = request.respond_to?(:user_agent) ? request.user_agent : request.env["HTTP_USER_AGENT"]
        Airbrake.configuration.ignore_user_agent.flatten.any? { |ua| ua === user_agent }
      end

      def airbrake_request_data
        { :parameters       => airbrake_filter_if_filtering(params.to_hash),
          :session_data     => airbrake_filter_if_filtering(airbrake_session_data),
          :controller       => params[:controller],
          :action           => params[:action],
          :url              => airbrake_request_url,
          :cgi_data         => airbrake_filter_if_filtering(request.env) }
      end

      def airbrake_filter_if_filtering(hash)
        return hash if ! hash.is_a?(Hash)

        if respond_to?(:filter_parameters)
          filter_parameters(hash) rescue hash
        else
          hash
        end
      end

      def airbrake_session_data
        if session.respond_to?(:to_hash)
          session.to_hash
        else
          session.data
        end
      end

      def airbrake_request_url
        url = "#{request.protocol}#{request.host}"

        unless [80, 443].include?(request.port)
          url << ":#{request.port}"
        end

        url << request.fullpath
        url
      end
    end
  end
end

