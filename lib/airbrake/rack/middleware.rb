module Airbrake
  module Rack
    # Airbrake Rack middleware for Rails and Sinatra applications (or any other
    # Rack-compliant app). Any errors raised by the upstream application will be
    # delivered to Airbrake and re-raised.
    #
    # The middleware automatically sends information about the framework that
    # uses it (name and version).
    class Middleware
      # @return [Array<Class>] the list of Rack filters that read Rack request
      #   information and append it to notices
      RACK_FILTERS = [
        Airbrake::Rack::ContextFilter,
        Airbrake::Rack::SessionFilter,
        Airbrake::Rack::HttpParamsFilter,
        Airbrake::Rack::HttpHeadersFilter

        # Optional filters (must be included by users):
        # Airbrake::Rack::RequestBodyFilter
      ].freeze

      # An Array that holds notifier names, which are known to be associated
      # with particular Airbrake Rack middleware.
      # rubocop:disable Style/ClassVars
      @@known_notifiers = []
      # rubocop:enable Style/ClassVars

      def initialize(app, notifier_name = :default)
        @app = app
        @notifier = Airbrake[notifier_name]

        # Prevent adding same filters to the same notifier.
        return if @@known_notifiers.include?(notifier_name)
        @@known_notifiers << notifier_name

        return unless @notifier
        RACK_FILTERS.each do |filter|
          @notifier.add_filter(filter.new)
        end
      end

      # Rescues any exceptions, sends them to Airbrake and re-raises the
      # exception.
      # @param [Hash] env the Rack environment
      def call(env)
        # rubocop:disable Lint/RescueException
        begin
          response = @app.call(env)
        rescue Exception => ex
          notify_airbrake(ex, env)
          raise ex
        end
        # rubocop:enable Lint/RescueException

        exception = framework_exception(env)
        notify_airbrake(exception, env) if exception

        response
      end

      private

      def notify_airbrake(exception, env)
        notice = @notifier.build_notice(exception)
        return unless notice

        # ActionDispatch::Request correctly captures server port when using SSL:
        # See: https://github.com/airbrake/airbrake/issues/802
        notice.stash[:rack_request] =
          if defined?(ActionDispatch::Request)
            ActionDispatch::Request.new(env)
          else
            ::Rack::Request.new(env)
          end

        @notifier.notify(notice)
      end

      # Web framework middlewares often store rescued exceptions inside the
      # Rack env, but Rack doesn't have a standard key for it:
      #
      # - Rails uses action_dispatch.exception: https://goo.gl/Kd694n
      # - Sinatra uses sinatra.error: https://goo.gl/LLkVL9
      # - Goliath uses rack.exception: https://goo.gl/i7e1nA
      def framework_exception(env)
        env['action_dispatch.exception'] ||
          env['sinatra.error'] ||
          env['rack.exception']
      end
    end
  end
end
