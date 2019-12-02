module Airbrake
  module Rails
    # App is a wrapper around Rails.application.
    #
    # @since v9.0.3
    # @api private
    class App
      Route = Struct.new(:path)

      # @param [] request
      # @return [Airbrake::Rails::App::Route, nil]
      def self.recognize_route(request)
        # Duplicate `request` because `recognize` *can* strip the request's
        # `path_info`, which results in broken engine links (when the engine has
        # an isolated namespace).
        ::Rails.application.routes.router.recognize(request.dup) do |route, _params|
          path =
            if route.app.respond_to?(:app) && route.app.app.respond_to?(:engine_name)
              "#{route.app.app.engine_name}##{route.path.spec}"
            else
              route.path.spec.to_s
            end

          # Rails can recognize multiple routes for the given request. For
          # example, if we visit /users/2/edit, then Rails sees these routes:
          #   * "/users/:id/edit(.:format)"
          #   *  "/"
          #
          # We return the first route as, what it seems, the most optimal
          # approach.
          return Route.new(path)
        end

        nil
      end
    end
  end
end
