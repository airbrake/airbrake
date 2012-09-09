namespace :airbrake do
  desc "Notify Airbrake of a new deploy."
  task :deploy do
    require 'airbrake_tasks'

    if defined?(Rails.root)
      initializer_file = Rails.root.join('config', 'initializers','airbrake.rb')

      if initializer_file.exist?
        load initializer_file
      else
        Rake::Task[:environment].invoke
      end
    end

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

      def heroku_var(var)
        `heroku config | grep -E "#{var.upcase}" | awk '{ print $3; }'`.strip
      end

      heroku_rails_env = heroku_var("rails_env")
      heroku_api_key = heroku_var("(hoptoad|airbrake)_api_key").split.find {|x| x unless x.blank?} ||
        Airbrake.configuration.api_key

      command = %Q(heroku addons:add deployhooks:http --url="http://airbrake.io/deploys.txt?deploy[rails_env]=#{heroku_rails_env}&api_key=#{heroku_api_key}")

      puts "\nRunning:\n#{command}\n"
      puts `#{command}`
    end
  end
end
