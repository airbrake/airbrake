namespace :airbrake do
  desc "Notify Airbrake of a new deploy."
  task :deploy => :environment do
    require 'airbrake_tasks'
    AirbrakeTasks.deploy(:rails_env      => ENV['TO'],
                        :scm_revision   => ENV['REVISION'],
                        :scm_repository => ENV['REPO'],
                        :local_username => ENV['USER'],
                        :api_key        => ENV['API_KEY'],
                        :dry_run        => ENV['DRY_RUN'])
  end

  task :log_stdout do
    require 'logger'
    RAILS_DEFAULT_LOGGER = Logger.new(STDOUT)
  end

  namespace :heroku do
    desc "Install Heroku deploy notifications addon"
    task :add_deploy_notification => [:environment] do
      heroku_api_key, heroku_rails_env = ["hoptoad_api_key", "rails_env"].map do |env_var|
        `heroku config | grep #{env_var.upcase} | awk '{ print $3; }'`.strip
      end

      heroku_api_key = Airbrake.configuration.api_key if heroku_api_key.blank?

      command = %Q(heroku addons:add deployhooks:http --url="http://airbrake.io/deploys.txt?deploy[rails_env]=#{heroku_rails_env}&api_key=#{heroku_api_key}")

      puts "\nRunning:\n#{command}\n"
      puts `#{command}`
    end
  end
end
