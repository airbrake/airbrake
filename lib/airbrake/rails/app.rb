module Airbrake
  module Rails
    # App is a wrapper around Rails.application.
    #
    # @since v9.0.3
    # @api private
    class App
      def self.recognize_route(request)
        ::Rails.application.routes.router.recognize(request) do |route, _params|
          # Rails can recognize multiple routes for the given request. For
          # example, if we visit /users/2/edit, then Rails sees these routes:
          #   * "/users/:id/edit(.:format)"
          #   *  "/"
          #
          # We return the first route as, what it seems, the most optimal
          # approach.
          return route
        end
      end
    end
  end
end
