# Defines deploy:notify_airbrake which will send information about the deploy to Airbrake.
require 'capistrano'

module Airbrake
  module Capistrano
    def self.load_into(configuration)
      configuration.load do
        after "deploy",            "airbrake:deploy"
        after "deploy:migrations", "airbrake:deploy"

        namespace :airbrake do
          desc <<-DESC
            Notify Airbrake of the deployment by running the notification on the REMOTE machine.
              - Run remotely so we use remote API keys, environment, etc.
          DESC
          task :deploy, :except => { :no_release => true } do
            rails_env = fetch(:airbrake_env, fetch(:rails_env, "production"))
            local_user = ENV['USER'] || ENV['USERNAME']
            executable = RUBY_PLATFORM.downcase.include?('mswin') ? fetch(:rake, 'rake.bat') : fetch(:rake, 'rake')
            directory = configuration.current_release
            notify_command = "cd #{directory}; #{executable} RAILS_ENV=#{rails_env} airbrake:deploy TO=#{rails_env} REVISION=#{current_revision} REPO=#{repository} USER=#{local_user}"
            notify_command << " DRY_RUN=true" if dry_run
            notify_command << " API_KEY=#{ENV['API_KEY']}" if ENV['API_KEY']
            logger.info "Notifying Airbrake of Deploy (#{notify_command})"
            if configuration.dry_run
              logger.info "DRY RUN: Notification not actually run."
            else
              result = ""
              run(notify_command, :once => true) { |ch, stream, data| result << data }
              # TODO: Check if SSL is active on account via result content.
            end
            logger.info "Airbrake Notification Complete."
          end
        end
      end
    end
  end
end

if Capistrano::Configuration.instance
  Airbrake::Capistrano.load_into(Capistrano::Configuration.instance)
end

