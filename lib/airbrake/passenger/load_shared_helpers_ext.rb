current_vsn = Gem::Version.new(PhusionPassenger::VERSION_STRING)
min_vsn = Gem::Version.new('4.0')
max_vsn = Gem::Version.new('5.1')

# Passenger may not be available at the moment.
# See https://goo.gl/UUFqYh
if defined?(PhusionPassenger) && current_vsn.between?(min_vsn, max_vsn)
  PhusionPassenger.require_passenger_lib('loader_shared_helpers')

  module PhusionPassenger
    ##
    # Redefine +PhusionPassenger::LoaderSharedHelpers+, so it can report errors
    # to Airbrake.
    module LoaderSharedHelpers
      alias_method :about_to_abort_without_airbrake, :about_to_abort

      ##
      # @see https://goo.gl/UE2EDe Passenger 4 method
      # @see https://goo.gl/F1e203 Passenger 5 method
      def about_to_abort(*args)
        exception = args.last
        return unless exception.is_a?(Exception)

        params = args.first
        params = {} if params == exception

        vsn = PhusionPassenger::VERSION_STRING
        params[:component] = "PhusionPassenger/#{params['passenger_version'] || vsn}"
        params[:action] = params['process_title'] || 'Unknown'
        Airbrake.notify_sync(exception, params)
      ensure
        about_to_abort_without_airbrake(*args)
      end
    end
  end
else
  message = "The Airbrake Passenger integration couldn't be loaded"
  # Warn because when we raise Bundler overwrites this message with its own
  # (can't require gem), which makes it impossible to debug.
  warn(message)
  raise message
end
