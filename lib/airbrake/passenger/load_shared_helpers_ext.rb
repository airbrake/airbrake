PhusionPassenger.require_passenger_lib('loader_shared_helpers')

module PhusionPassenger
  ##
  # Redefine +PhusionPassenger::LoaderSharedHelpers+, so it can report errors to
  # Airbrake.
  module LoaderSharedHelpers
    alias_method :about_to_abort_without_airbrake, :about_to_abort

    def about_to_abort(*args)
      exception = args.last
      return unless exception.is_a?(Exception)

      params = args.first
      params[:component] = "PhusionPassenger/#{params['passenger_version']}"
      params[:action] = params['process_title']
      Airbrake.notify_sync(exception, params)
    ensure
      about_to_abort_without_airbrake(*args)
    end
  end
end
