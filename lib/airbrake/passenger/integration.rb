module Airbrake
  # Integration for Phusion Passenger
  module Passenger
    IntegrationError = Class.new(::StandardError)
    class << self
      def notifier
        @notifier || :default
      end

      def notifier=(val)
        if val.is_a?(Symbol)
          @notifier = val
        else
          @notifier = val.to_sym
        end
      end
    end
    # Implementation of Passenger Integration for Versions 4.0 thru 5.0
    module Integration
      VERSION_REQUIREMENT = Gem::Requirement.new('>= 4.0', '< 5.1').freeze
      class << self
        def integrate!
          return @integrated if defined?(@integrated)
          raise IntegrationError, "Your version of PhusionPassenger " \
            "is not currently supported by the airbrake gem." unless compatible?
          unless defined?(::PhusionPassenger::LoaderSharedHelpers)
            ::PhusionPassenger.require_passenger_lib 'loader_shared_helpers'
          end
          ::PhusionPassenger::LoaderSharedHelpers.send :extend, ClassMethods
        rescue IntegrationError => e
          Kernel.warn e
          ::Airbrake.notify_sync(e, {}, notifier)
          @integrated = false
        else
          @integrated = true
        end

        def compatible?
          @compatible ||= VERSION_REQUIREMENT.satisfied_by?(passenger_version)
        end

        private

        def passenger_version
          @passenger_version ||= begin
            unless defined?(::PhusionPassenger)
              raise IntegrationError, "PhusionPassenger not detected."
            end
            Gem::Version.new(::PhusionPassenger::VERSION_STRING)
          end
        end
      end

      autoload :ClassMethods, 'airbrake/passenger/integration/class_methods'
    end
  end
end

Airbrake::Passenger::Integration.integrate!
