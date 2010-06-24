module HoptoadNotifier

  if defined? ActionDispatch::Http::FilterParameters
    class FilterableHash < Hash
      include ActionDispatch::Http::FilterParameters

      def filter_for_request(request)
        @env = request.env
        process_parameter_filter(self)
      end
    end
  end

  module Rails
    module ControllerMethods
      private

      # This method should be used for sending manual notifications while you are still
      # inside the controller. Otherwise it works like HoptoadNotifier.notify.
      def notify_hoptoad(hash_or_exception)
        unless consider_all_requests_local || local_request?
          HoptoadNotifier.notify(hash_or_exception, hoptoad_request_data)
        end
      end

      def hoptoad_ignore_user_agent? #:nodoc:
        # Rails 1.2.6 doesn't have request.user_agent, so check for it here
        user_agent = request.respond_to?(:user_agent) ? request.user_agent : request.env["HTTP_USER_AGENT"]
        HoptoadNotifier.configuration.ignore_user_agent.flatten.any? { |ua| ua === user_agent }
      end

      def hoptoad_request_data
        { :parameters       => hoptoad_filter_if_filtering(params.to_hash),
          :session_data     => hoptoad_filter_if_filtering(hoptoad_session_data),
          :controller       => params[:controller],
          :action           => params[:action],
          :url              => hoptoad_request_url,
          :cgi_data         => hoptoad_filter_if_filtering(request.env) }
      end

      def hoptoad_filter_if_filtering(hash)
        puts "*"*80
        puts "Filtering:"
        p hash
        puts "*"*80

        return hash if ! hash.is_a?(Hash)

        # if respond_to?(:filter_parameters)
        #   puts "*"*80
        #   puts "Filtering hash:"
        #   p hash
        #   retval = filter_parameters(hash) rescue hash
        #   puts "Got result:"
        #   p retval
        #   puts "*"*80

        #   filter_parameters(hash) rescue hash
        # else
        #   hash
        # end

        if respond_to?(:filter_parameters)
          retval = filter_parameters(hash) rescue hash
        elsif defined? ActionDispatch::Http::FilterParameters
          puts "And filtering it"
          retval = FilterableHash[hash].filter_for_request(request) rescue hash
          puts "And returning:"
          p retval
          retval
        else
          puts "Not filtering it"
          hash
        end

      end

      def hoptoad_session_data
        if session.respond_to?(:to_hash)
          session.to_hash
        else
          session.data
        end
      end

      def hoptoad_request_url
        url = "#{request.protocol}#{request.host}"

        unless [80, 443].include?(request.port)
          url << ":#{request.port}"
        end

        url << request.request_uri
        url
      end
    end
  end
end

