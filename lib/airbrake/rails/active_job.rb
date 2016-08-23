module Airbrake
  module Rails
    ##
    # Enables support for exceptions occurring in ActiveJob jobs.
    module ActiveJob
      extend ActiveSupport::Concern

      included do
        if ::Rails.application.config.respond_to?(:active_job)
          active_job_cfg = ::Rails.application.config.active_job
          is_resque_adapter = (active_job_cfg.queue_adapter == :resque)
        end

        rescue_from(Exception) do |exception|
          if (notice = Airbrake.build_notice(exception))
            notice[:context][:component] = 'active_job'
            notice[:context][:action] = self.class.name

            notice[:params] = serialize

            # We special case Resque because it kills our workers by forking, so
            # we use synchronous delivery instead.
            if is_resque_adapter
              Airbrake.notify_sync(notice)
            else
              Airbrake.notify(notice)
            end
          end

          raise exception
        end
      end
    end
  end
end
