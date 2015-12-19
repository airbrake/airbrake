module Delayed
  module Plugins
    ##
    # Provides integration with Delayed Job.
    # rubocop:disable Lint/RescueException
    class Airbrake < ::Delayed::Plugin
      callbacks do |lifecycle|
        lifecycle.around(:invoke_job) do |job, *args, &block|
          begin
            # Forward the call to the next callback in the callback chain
            block.call(job, *args)
          rescue Exception => exception
            params = job.as_json.merge(
              component: 'delayed_job',
              action: job.payload_object.class.name
            )

            # If DelayedJob is used through ActiveJob, it contains extra info.
            if job.payload_object.respond_to?(:job_data)
              params[:active_job] = job.payload_object.job_data
            end

            ::Airbrake.notify(exception, params)
            raise exception
          end
        end
      end
    end
    # rubocop:enable Lint/RescueException
  end
end

if RUBY_ENGINE == 'jruby' && defined?(Delayed::Backend::ActiveRecord::Job)
  ##
  # Workaround against JRuby bug:
  # https://github.com/jruby/jruby/issues/3338
  # rubocop:disable Style/ClassAndModuleChildren
  class Delayed::Backend::ActiveRecord::Job
    alias_method :old_to_ary, :to_ary

    def to_ary
      old_to_ary || [self]
    end
  end
  # rubocop:enable Style/ClassAndModuleChildren
end

Delayed::Worker.plugins << Delayed::Plugins::Airbrake
