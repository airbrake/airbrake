module Airbrake
  module Rack
    ##
    # A helper class for filling notices with all sorts of useful information
    # coming from the Rack environment.
    class NoticeBuilder
      @builders = []

      class << self
        ##
        # @return [Array<#call>] the list of notice's builders
        attr_reader :builders

        ##
        # Adds user defined builders to the chain.
        def add_builder(&block)
          @builders << block
        end
      end

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
        @request = ::Rack::Request.new(rack_env)
      end

      ##
      # Adds context, session, params and other fields based on the Rack env.
      #
      # @param [Exception] exception
      # @return [Airbrake::Notice] the notice with extra information
      def build_notice(exception)
        return unless (notice = Airbrake.build_notice(exception))

        NoticeBuilder.builders.each { |builder| builder.call(notice, @request) }
        notice
      end

      # Adds context (url, user agent, framework version, controller, etc)
      add_builder do |notice, request|
        context = notice[:context]

        context[:url] = request.url
        context[:userAgent] = request.user_agent

        framework_version =
          if defined?(::Rails)
            "Rails/#{::Rails.version}"
          elsif defined?(::Sinatra)
            "Sinatra/#{Sinatra::VERSION}"
          else
            "Rack.version/#{::Rack.version} Rack.release/#{::Rack.release}"
          end.freeze

        if context.key?(:version)
          context[:version] += " #{framework_version}"
        else
          context[:version] = framework_version
        end

        controller = request.env['action_controller.instance']
        if controller
          context[:component] = controller.controller_name
          context[:action] = controller.action_name
        end

        user = Airbrake::Rack::User.extract(request.env)
        notice[:context].merge!(user.as_json) if user

        nil
      end

      # Adds session
      add_builder do |notice, request|
        session = request.session
        notice[:session] = session if session
      end

      # Adds request params
      add_builder do |notice, request|
        params = request.env['action_dispatch.request.parameters']
        notice[:params] = params if params
      end

      # Adds http referer, method and headers to the environment
      add_builder do |notice, request|
        http_headers = request.env.map.with_object({}) do |(key, value), headers|
          if HTTP_HEADER_PREFIXES.any? { |prefix| key.to_s.start_with?(prefix) }
            headers[key] = value
          end

          headers
        end

        notice[:environment].merge!(
          httpMethod: request.request_method,
          referer: request.referer,
          headers: http_headers
        )
      end
    end
  end
end
