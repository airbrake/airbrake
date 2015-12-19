require 'shellwords'
require 'fileutils'

if defined?(Capistrano::VERSION) &&
   Gem::Version.new(Capistrano::VERSION).release >= Gem::Version.new('3.0.0')
  namespace :airbrake do
    desc "Notify Airbrake of the deploy"
    task :deploy do
      on roles(:all) do
        within release_path do
          with rails_env: fetch(:rails_env, fetch(:stage)) do
            execute :rake, <<-CMD
              airbrake:deploy USERNAME=#{Shellwords.shellescape(local_user)} \
                              ENVIRONMENT=#{fetch(:rails_env, fetch(:stage))} \
                              REVISION=#{fetch(:current_revision)} \
                              REPOSITORY=#{fetch(:repo_url)} \
                              VERSION=#{fetch(:app_version)}
            CMD

            info 'Notified Airbrake of the deploy'
          end
        end
      end
    end
  end
else
  module Airbrake
    ##
    # The Capistrano v2 integration.
    module Capistrano
      # rubocop:disable Metrics/AbcSize
      def self.load_into(config)
        config.load do
          after 'deploy',            'airbrake:deploy'
          after 'deploy:migrations', 'airbrake:deploy'
          after 'deploy:cold',       'airbrake:deploy'

          namespace :airbrake do
            desc "Notify Airbrake of the deploy"
            task :deploy, except: { no_release: true }, on_error: :continue do
              FileUtils.cd(config.release_path) do
                username = Shellwords.shellescape(ENV['USER'] || ENV['USERNAME'])

                system(<<-CMD)
                  bundle exec rake airbrake:deploy \
                    USERNAME=#{username} \
                    ENVIRONMENT=#{fetch(:rails_env, 'production')} \
                    REVISION=#{current_revision.strip} \
                    REPOSITORY=#{repository} \
                    VERSION=#{fetch(:app_version, nil)}
                CMD
              end

              logger.info 'Notified Airbrake of the deploy'
            end
          end
        end
      end
      # rubocop:enable Metrics/AbcSize
    end
  end

  Airbrake::Capistrano.load_into(Capistrano::Configuration.instance)
end
