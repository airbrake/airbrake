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
        request_copy = request.dup

        # We must search every engine individually to find a concrete route. If
        # we rely only on the `Rails.application.routes.router`, then the
        # recognize call would return the root route, neglecting PATH_INFO
        # completely. For example:
        #   * a request is made to `marketing#pricing`
        #   * `Rails.application` recognizes it as `marketing#/` (incorrect)
        #   * `Marketing::Engine` recognizes it as `marketing#/pricing` (correct)
        engines.each do |engine|
          engine.routes.router.recognize(request_copy) do |route, _params|
            path =
              if engine == ::Rails.application
                route.path.spec.to_s
              else
                "#{engine.engine_name}##{route.path.spec}"
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
        end

        nil
      end

      def self.engines
        @engines ||= [*::Rails::Engine.subclasses, ::Rails.application]
      end
      private_class_method :engines
    end
  end
end
