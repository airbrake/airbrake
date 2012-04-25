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
      cedar = !`heroku stack | grep \*\ cedar`.blank?
      run = cedar ? " run " : ""
      heroku_api_key = `heroku #{run} console 'puts ENV[%{HOPTOAD_API_KEY}]' | head -n 1`.strip
      heroku_rails_env = `heroku #{run} console 'puts RAILS_ENV' | head -n 1`.strip

      command = %Q(heroku addons:add deployhooks:http --url="http://airbrake.io/deploys.txt?deploy[rails_env]=#{heroku_rails_env}&api_key=#{heroku_api_key}")

      puts "\nRunning:\n#{command}\n"
      puts `#{command}`
    end
  end
end
