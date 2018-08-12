module Airbrake
  module Rack
    # Adds route slugs to context/route.
    # @since v7.5.0
    class RouteFilter
      attr_reader :weight

      def initialize
        @weight = 100
      end

      def call(notice)
        return unless (request = notice.stash[:rack_request])

        notice[:context][:route] =
          if defined?(ActionDispatch::Request) &&
             request.instance_of?(ActionDispatch::Request)
            rails_route(request)
          elsif defined?(Sinatra::Request) &&
                request.instance_of?(Sinatra::Request)
            sinatra_route(request)
          end
      end

      private

      def rails_route(request)
        ::Rails.application.routes.router.recognize(request) do |route, _parameters|
          # Rails can recognize multiple routes for the given request. For
          # example, if we visit /users/2/edit, then Rails sees these routes:
          #   * "/users/:id/edit(.:format)"
          #   *  "/"
          #
          # We return the first route as, what it seems, the most optimal
          # approach.
          return route.path.spec.to_s
        end
      end

      def sinatra_route(request)
        request.env['sinatra.route'].split(' ').drop(1).join(' ')
      end
    end
  end
end
