# frozen_string_literal: true

module Airbrake
  module Rails
    # This railtie works for any Rails application that supports railties (Rails
    # 3.2+ apps). It makes Airbrake Ruby work with Rails and report errors
    # occurring in the application automatically.
    class Railtie < ::Rails::Railtie
      initializer('airbrake.middleware') do |app|
        require 'airbrake/rails/railties/middleware_tie'
        Railties::MiddlewareTie.new(app).call
      end

      rake_tasks do
        # Report exceptions occurring in Rake tasks.
        require 'airbrake/rake'

        # Defines tasks such as `airbrake:test` & `airbrake:deploy`.
        require 'airbrake/rake/tasks'
      end

      initializer('airbrake.action_controller') do
        require 'airbrake/rails/railties/action_controller_tie'
        Railties::ActionControllerTie.new.call
      end

      initializer('airbrake.active_record') do
        require 'airbrake/rails/railties/active_record_tie'
        Railties::ActiveRecordTie.new.call
      end

      initializer('airbrake.active_job') do
        ActiveSupport.on_load(:active_job, run_once: true) do
          # Reports exceptions occurring in ActiveJob jobs.
          require 'airbrake/rails/active_job'
          include Airbrake::Rails::ActiveJob
        end
      end

      initializer('airbrake.action_cable') do
        ActiveSupport.on_load(:action_cable, run_once: true) do
          # Reports exceptions occurring in ActionCable connections.
          require 'airbrake/rails/action_cable'
        end
      end

      runner do
        at_exit do
          Airbrake.notify_sync($ERROR_INFO) if $ERROR_INFO
        end
      end
    end
  end
end
