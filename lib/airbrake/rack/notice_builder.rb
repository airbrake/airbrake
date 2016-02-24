module Airbrake
  module Rack
    ##
    # A helper class for filling notices with all sorts of useful information
    # coming from the Rack environment.
    class NoticeBuilder
      ##
      # @return [Array<String>] the prefixes of the majority of HTTP headers in
      #   Rack (some prefixes match the header names for simplicity)
      HTTP_HEADER_PREFIXES = [
        'HTTP_'.freeze,
        'CONTENT_TYPE'.freeze,
        'CONTENT_LENGTH'.freeze
      ].freeze

      ##
      # @param [Hash{String=>Object}] rack_env The Rack environment
      def initialize(rack_env)
        @rack_env = rack_env
        @request = ::Rack::Request.new(rack_env)
        @controller = rack_env['action_controller.instance']
        @session = @request.session
        @user = Airbrake::Rack::User.extract(rack_env)

        @framework_version =
          if defined?(::Rails)
            "Rails/#{::Rails.version}"
          elsif defined?(::Sinatra)
            "Sinatra/#{Sinatra::VERSION}"
          else
            "Rack.version/#{::Rack.version} Rack.release/#{::Rack.release}"
          end.freeze
      end

      ##
      # Adds context, session, params and other fields based on the Rack env.
      #
      # @param [Exception] exception
      # @return [Airbrake::Notice] the notice with extra information
      def build_notice(exception)
        notice = Airbrake.build_notice(exception)

        add_context(notice)
        add_session(notice)
        add_params(notice)
        add_environment(notice)
        add_metadata(notice)

        notice
      end

      private

      def add_context(notice)
        context = notice[:context]

        context[:url] = @request.url
        context[:userAgent] = @request.user_agent

        if context.key?(:version)
          context[:version] += " #{@framework_version}"
        else
          context[:version] = @framework_version
        end

        if @controller
          context[:component] = @controller.controller_name
          context[:action] = @controller.action_name
        end

        notice[:context].merge!(@user.as_json) if @user

        nil
      end

      def add_session(notice)
        notice[:session] = @session if @session
      end

      def add_params(notice)
        params = @request.env['action_dispatch.request.parameters']
        notice[:params] = params if params
      end

      def add_metadata(notice)
        # This method does nothing by default, but it can be overridden to add any custom
        # data from RACK environment to the notice.
      end

      def add_environment(notice)
        notice[:environment].merge!(
          httpMethod: @request.request_method,
          referer: @request.referer,
          headers: request_headers
        )
      end

      def request_headers
        @rack_env.map.with_object({}) do |(key, value), headers|
          if HTTP_HEADER_PREFIXES.any? { |prefix| key.to_s.start_with?(prefix) }
            headers[key] = value
          end

          headers
        end
      end
    end
  end
end
