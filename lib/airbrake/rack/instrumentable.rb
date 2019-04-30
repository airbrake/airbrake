module Airbrake
  module Rack
    # Instrumentable holds methods that simplify instrumenting Rack apps.
    # @example
    #   class UsersController
    #     extend Airbrake::Rack::Instrumentable
    #
    #     def index
    #       # ...
    #     end
    #     airbrake_capture_timing :index
    #   end
    #
    # @api public
    # @since v9.2.0
    module Instrumentable
      def airbrake_capture_timing(method_name)
        alias_method "#{method_name}_without_airbrake", method_name

        define_method(method_name) do |*args|
          Airbrake::Rack.capture_timing(method_name.to_s) do
            __send__("#{method_name}_without_airbrake", *args)
          end
        end
      end
    end
  end
end
