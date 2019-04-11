module Airbrake
  module Rails
    # App is a wrapper around Rails.application and Rails::Engine.
    #
    # @since v9.0.3
    # @api private
    class App
      Route = Struct.new(:path, :controller, :action)

      def routes
        @routes ||= [*app_routes, *engine_routes].map do |route|
          Route.new(
            route.path.spec.to_s,
            route.defaults[:controller],
            route.defaults[:action]
          )
        end
      end

      private

      def app_routes
        ::Rails.application.routes.routes.routes
      end

      def engine_routes
        ::Rails::Engine.subclasses.flat_map do |engine|
          engine.routes.routes.routes
        end
      end
    end
  end
end
