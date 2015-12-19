module Airbrake
  module Rails
    ##
    # Enables support for exceptions occurring in ActiveJob jobs.
    module ActiveJob
      extend ActiveSupport::Concern

      included do
        rescue_from(Exception) do |exception|
          notice = Airbrake.build_notice(exception)

          notice[:context][:component] = self.class.name
          notice[:context][:action] = job_id

          notice[:params] = as_json

          Airbrake.notify(notice)
          raise exception
        end
      end
    end
  end
end
