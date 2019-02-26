module Airbrake
  module Rack
    # Airbrake Rack middleware for Rails and Sinatra applications (or any other
    # Rack-compliant app). Any errors raised by the upstream application will be
    # delivered to Airbrake and re-raised.
    #
    # The middleware automatically sends information about the framework that
    # uses it (name and version).
    #
    # For Rails apps the middleware collects route performance statistics.
    class Middleware
      # @return [Array<Class>] the list of Rack filters that read Rack request
      #   information and append it to notices
      RACK_FILTERS = [
        Airbrake::Rack::ContextFilter,
        Airbrake::Rack::UserFilter,
        Airbrake::Rack::SessionFilter,
        Airbrake::Rack::HttpParamsFilter,
        Airbrake::Rack::HttpHeadersFilter,
        Airbrake::Rack::RouteFilter,

        # Optional filters (must be included by users):
        # Airbrake::Rack::RequestBodyFilter
      ].freeze

      def initialize(app)
        @app = app

        RACK_FILTERS.each { |filter| Airbrake.add_filter(filter.new) }

        install_action_controller_hooks if defined?(Rails)
        install_active_record_hooks if defined?(ActiveRecord)
      end

      # Thread-safe {call!}.
      #
      # @param [Hash] env the Rack environment
      # @see https://github.com/airbrake/airbrake/issues/904
      def call(env)
        dup.call!(env)
      end

      # Rescues any exceptions, sends them to Airbrake and re-raises the
      # exception. We also duplicate middleware to guarantee thread-safety.
      #
      # @param [Hash] env the Rack environment
      def call!(env)
        # Rails hooks such as ActionControllerRouteSubscriber rely on this.
        RequestStore[:routes] = {}

        begin
          response = @app.call(env)
        rescue Exception => ex # rubocop:disable Lint/RescueException
          notify_airbrake(ex, env)
          raise ex
        ensure
          # Clear routes for the next request.
          RequestStore.clear
        end

        exception = framework_exception(env)
        notify_airbrake(exception, env) if exception

        response
      end

      private

      def notify_airbrake(exception, env)
        notice = Airbrake.build_notice(exception)
        return unless notice

        # ActionDispatch::Request correctly captures server port when using SSL:
        # See: https://github.com/airbrake/airbrake/issues/802
        notice.stash[:rack_request] =
          if defined?(ActionDispatch::Request)
            ActionDispatch::Request.new(env)
          elsif defined?(Sinatra::Request)
            Sinatra::Request.new(env)
          else
            ::Rack::Request.new(env)
          end

        Airbrake.notify(notice)
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

      def install_action_controller_hooks
        ActiveSupport::Notifications.subscribe(
          'start_processing.action_controller',
          Airbrake::Rails::ActionControllerRouteSubscriber.new
        )

        ActiveSupport::Notifications.subscribe(
          'process_action.action_controller',
          Airbrake::Rails::ActionControllerNotifySubscriber.new
        )
      end

      def install_active_record_hooks
        Airbrake.add_performance_filter(
          Airbrake::Filters::SqlFilter.new(
            ActiveRecord::Base.connection_config[:adapter]
          )
        )
        ActiveSupport::Notifications.subscribe(
          'sql.active_record',
          Airbrake::Rails::ActiveRecordSubscriber.new
        )
      end
    end
  end
end
