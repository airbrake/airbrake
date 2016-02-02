module Airbrake
  module Rack
    ##
    # A helper class for filling notices with all sorts of useful information
    # coming from the Rack environment.
    class NoticeBuilder
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
    end
  end
end
