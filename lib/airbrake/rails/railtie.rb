module Airbrake
  module Rails
    ##
    # This railtie works for any Rails application that supports railties (Rails
    # 3.2+ apps). It makes Airbrake Ruby work with Rails and report errors
    # occurring in the application automatically.
    class Railtie < ::Rails::Railtie
      initializer('airbrake.middleware') do |app|
        # Since Rails 3.2 the ActionDispatch::DebugExceptions middleware is
        # responsible for logging exceptions and showing a debugging page in
        # case the request is local. We want to insert our middleware after
        # DebugExceptions, so we don't notify Airbrake about local requests.

        if ::Rails.version =~ /\A5\./
          # Avoid the warning about deprecated strings.
          app.config.middleware.insert_after(
            ActionDispatch::DebugExceptions, Airbrake::Rack::Middleware
          )
        else
          app.config.middleware.insert_after(
            ActionDispatch::DebugExceptions, 'Airbrake::Rack::Middleware'
          )
        end
      end

      rake_tasks do
        # Report exceptions occurring in Rake tasks.
        require 'airbrake/rake/task_ext'

        # Defines tasks such as `airbrake:test` & `airbrake:deploy`.
        require 'airbrake/rake/tasks'
      end

      initializer('airbrake.action_controller') do
        ActiveSupport.on_load(:action_controller) do
          # Patches ActionController with methods that allow us to retrieve
          # interesting request data. Appends that information to notices.
          require 'airbrake/rails/action_controller'
          include Airbrake::Rails::ActionController
        end
      end

      initializer('airbrake.active_record') do
        ActiveSupport.on_load(:active_record) do
          # Reports exceptions occurring in some bugged ActiveRecord callbacks.
          # Applicable only to the versions of Rails lower than 4.2.
          require 'airbrake/rails/active_record'
          include Airbrake::Rails::ActiveRecord
        end
      end

      initializer('airbrake.active_job') do
        ActiveSupport.on_load(:active_job) do
          # Reports exceptions occurring in ActiveJob jobs.
          require 'airbrake/rails/active_job'
          include Airbrake::Rails::ActiveJob
        end
      end
    end
  end
end
