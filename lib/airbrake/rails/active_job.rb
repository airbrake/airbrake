module Airbrake
  module Rails
    ##
    # Enables support for exceptions occurring in ActiveJob jobs.
    module ActiveJob
      extend ActiveSupport::Concern

      included do
        rescue_from(Exception) do |exception|
          notice = Airbrake.build_notice(exception)

          notice[:context][:component] = 'active_job'
          notice[:context][:action] = self.class.name

          notice[:params] = as_json

          Airbrake.notify(notice)
          raise exception
        end
      end
    end
  end
end
