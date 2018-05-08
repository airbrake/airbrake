module Airbrake
  module Rack
    # Adds context (URL, User-Agent, framework version, controller and more).
    #
    # @since v5.7.0
    class ContextFilter
      # @return [Integer]
      attr_reader :weight

      def initialize
        @framework_version =
          if defined?(::Rails) && ::Rails.respond_to?(:version)
            { 'rails' => ::Rails.version }
          elsif defined?(::Sinatra)
            { 'sinatra' => Sinatra::VERSION }
          else
            {
              'rack_version' => ::Rack.version,
              'rack_release' => ::Rack.release
            }
          end
        @weight = 99
      end

      # @see Airbrake::FilterChain#refine
      def call(notice)
        return unless (request = notice.stash[:rack_request])

        context = notice[:context]

        context[:url] = request.url
        context[:userAddr] = request.ip
        context[:userAgent] = request.user_agent

        add_framework_version(context)

        controller = request.env['action_controller.instance']
        if controller
          context[:component] = controller.controller_name
          context[:action] = controller.action_name
        end

        user = Airbrake::Rack::User.extract(request.env)
        notice[:context].merge!(user.as_json) if user
      end

      private

      def add_framework_version(context)
        if context.key?(:versions)
          context[:versions].merge!(@framework_version)
        else
          context[:versions] = @framework_version
        end
      end
    end
  end
end
