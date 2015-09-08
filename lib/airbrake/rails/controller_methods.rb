module Airbrake
  module Rails
    module ControllerMethods

      def airbrake_request_data
        {
          :parameters       => airbrake_filter_if_filtering(params.to_hash),
          :session_data     => airbrake_filter_if_filtering(airbrake_session_data),
          :controller       => params[:controller],
          :action           => params[:action],
          :url              => airbrake_request_url,
          :cgi_data         => airbrake_filter_if_filtering(request.env),
          :user             => airbrake_current_user || {}
        }
      end

      private

      # This method should be used for sending manual notifications while you are still
      # inside the controller. Otherwise it works like Airbrake.notify.
      def notify_airbrake(hash_or_exception)
        unless airbrake_local_request?
          Airbrake.notify_or_ignore(hash_or_exception, airbrake_request_data)
        end
      end

      def airbrake_local_request?
        if defined?(::Rails.application.config)
          ::Rails.application.config.consider_all_requests_local || (request.local? && (!request.env["HTTP_X_FORWARDED_FOR"]))
        else
          consider_all_requests_local || (local_request? && (!request.env["HTTP_X_FORWARDED_FOR"]))
        end
      end

      def airbrake_ignore_user_agent? #:nodoc:
        # Rails 1.2.6 doesn't have request.user_agent, so check for it here
        user_agent = request.respond_to?(:user_agent) ? request.user_agent : request.env["HTTP_USER_AGENT"]
        Airbrake.configuration.ignore_user_agent.flatten.any? { |ua| ua === user_agent }
      end


      def airbrake_filter_if_filtering(hash)
        return hash if ! hash.is_a?(Hash)

        if respond_to?(:filter_parameters) # Rails 2
          filter_parameters(hash)
        elsif rails_3_or_4?
          filter_rails3_parameters(hash)
        else
          hash
        end
      end

      def rails_3_or_4?
        defined?(::Rails.version) && ::Rails.version =~ /\A[34]/
      end

      def filter_rails3_parameters(hash)
        ActionDispatch::Http::ParameterFilter.new(
          ::Rails.application.config.filter_parameters
        ).filter(recursive_stringify_keys(hash))
      end

      def recursive_stringify_keys(hash)
        hash = hash.stringify_keys
        hash.each do |k, v|
          if v.is_a?(Hash)
            hash[k] = v.respond_to?(:stringify_keys) ? recursive_stringify_keys(v) : nil # Rack::Session::Abstract::SessionHash has a stringify_keys method we should not call
          end
        end
        hash
      end

      def airbrake_session_data
        if session
          if session.respond_to?(:to_hash)
            session.to_hash
          else
            session.data
          end
        else
          {:session => 'no session found'}
        end
      end

      def airbrake_request_url
        url = "#{request.protocol}#{request.host}"

        unless [80, 443].include?(request.port)
          url << ":#{request.port}"
        end

        URI.join(url, request.fullpath).to_s
      end

      def airbrake_current_user
        user = fetch_user

        if user
          Airbrake.configuration.user_attributes.map(&:to_sym).inject({}) do |hsh, attr|
            hsh[attr.to_sym] = user.send(attr) if user.respond_to? attr
            hsh
          end
        end
      end

      def fetch_user
        if defined?(current_user)
          current_user
        elsif defined?(current_member)
          current_member
        else
          nil
        end
      ensure
        # The Airbrake middleware is first in the chain, before ActiveRecord::ConnectionAdapters::ConnectionManagement
        # kicks in to do its thing. This can cause the connection pool to run out of connections.
        if defined?(ActiveRecord::Base) && ActiveRecord::Base.respond_to?(:connection_pool)
          ActiveRecord::Base.connection_pool.release_connection
        end
      end
    end
  end
end
