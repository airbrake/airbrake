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

      def get_heroku_vars
        config = `heroku config --shell`
        array_of_vars = config.split.map do |var|
          var.partition("=").tap {|part| part.delete_at(1)}
        end.flatten
        @heroku_vars = Hash[*array_of_vars]
      end

      get_heroku_vars

      heroku_rails_env = @heroku_vars["RAILS_ENV"]        || ENV["RAILS_ENV"] || "production"
      heroku_api_key   = @heroku_vars["AIRBRAKE_API_KEY"] || Airbrake.configuration.api_key || ENV["AIRBRAKE_API_KEY"]
      heroku_app       = ENV["HEROKU_APP"]
      repo             = `git config --get remote.origin.url` || ENV["REPO"]

      command = %Q(heroku addons:add deployhooks:http --url="http://airbrake.io/deploys.txt?api_key=#{heroku_api_key})
      command << "&deploy[local_username]={{user}}"    
      command << "&deploy[scm_revision]={{head_long}}" 
      command << "&deploy[rails_env]=#{heroku_rails_env}"  if heroku_rails_env
      command << "&deploy[scm_repository]=#{repo}"         if repo
      command << '"'
      command << " --app=#{heroku_app}"                    if heroku_app

      puts "\nRunning:\n#{command}\n"
      puts `#{command}`
    end
  end
end
