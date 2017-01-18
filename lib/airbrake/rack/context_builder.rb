module Airbrake
  module Rack
    ##
    # Adds context (URL, User-Agent, framework version, controller and more).
    #
    # @since v5.7.0
    class ContextBuilder
      def initialize
        @framework_version =
          if defined?(::Rails)
            "Rails/#{::Rails.version}"
          elsif defined?(::Sinatra)
            "Sinatra/#{Sinatra::VERSION}"
          else
            "Rack.version/#{::Rack.version} Rack.release/#{::Rack.release}"
          end.freeze
      end

      def call(notice, request)
        context = notice[:context]

        context[:url] = request.url
        context[:userAgent] = request.user_agent

        if context.key?(:version)
          context[:version] += " #{@framework_version}"
        else
          context[:version] = @framework_version
        end

        controller = request.env['action_controller.instance']
        if controller
          context[:component] = controller.controller_name
          context[:action] = controller.action_name
        end

        user = Airbrake::Rack::User.extract(request.env)
        notice[:context].merge!(user.as_json) if user
      end
    end
  end
end
