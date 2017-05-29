require 'airbrake/passenger/integration'
module Airbrake
  module Passenger
    module Integration
      # Module to be extended into ::PhusionPassenger::LoaderSharedHelpers
      module ClassMethods
        def self.extended(klass)
          if klass.respond_to?(:about_to_abort)
            klass.send :alias_method, :about_to_abort_without_notifier, :about_to_abort
          end
        end

        def about_to_abort(*args)
          exception = args.last if args.last.is_a?(Exception)
          if exception
            params = {}
            params[:component] = "PhusionPassenger " \
              "v#{::PhusionPassenger::VERSION_STRING}"
            # TODO: Add more contextual info here
            ::Airbrake.notify_sync(exception, params, ::Airbrake::Passenger.notifier)
          end
          return unless respond_to?(:about_to_abort_without_notifier)
          about_to_abort_without_notifier(*args)
        end
      end
    end
  end
end
