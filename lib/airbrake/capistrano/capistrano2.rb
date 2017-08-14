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
            username = Shellwords.shellescape(ENV['USER'] || ENV['USERNAME'])
            command = <<-CMD
              cd #{config.release_path} && \

              RACK_ENV=#{fetch(:rack_env, nil)} \
              RAILS_ENV=#{fetch(:rails_env, nil)} \

              bundle exec rake airbrake:deploy \
                USERNAME=#{username} \
                ENVIRONMENT=#{fetch(:rails_env, 'production')} \
                REVISION=#{current_revision.strip} \
                REPOSITORY=#{repository} \
                VERSION=#{fetch(:app_version, nil)}
            CMD

            run(command, once: true)
            logger.info 'Notified Airbrake of the deploy'
          end
        end
      end
    end
    # rubocop:enable Metrics/AbcSize
  end
end

Airbrake::Capistrano.load_into(Capistrano::Configuration.instance)
