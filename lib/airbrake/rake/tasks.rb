namespace :airbrake do
  desc 'Verify your gem installation by sending a test exception'
  task test: :environment do
    require 'pp'

    begin
      raise StandardError, 'Exception from the test Rake task'
    rescue => ex
      response = Airbrake.notify_sync(ex)
    end

    notifiers = Airbrake.instance_variable_get(:@notifiers).map do |name, notif|
      cfg = notif.instance_variable_get(:@config)
      filters = notif.instance_variable_get(:@filter_chain)
      "#{name}:\n  " + [cfg, filters].pretty_inspect
    end.join("\n")

    if !response
      puts <<-NORESPONSE.gsub(/^\s+\|/, '')
        |Couldn't send a test exception. There are two reasons for this:
        |
        |1. Airbrake ignored this exception due to misconfigured filters
        |2. Airbrake was configured to ignore the '#{Rails.env}' environment.
        |   To fix this try one of the following:
        |     * specify another environment via RAILS_ENV
        |     * temporarily unignore the '#{Rails.env}' environment
      NORESPONSE
    elsif response['error']
      puts <<-ERROR.gsub(/^\s+\|/, '')
        |Error occurred: #{response['error']}
        |Make sure that your Project ID and Project Key are correct:
        |https://github.com/airbrake/airbrake-ruby#project_id--project_key
      ERROR
    else
      puts <<-OUTPUT.gsub(/^\s+\|/, '')
        |[ruby]
        |description: #{RUBY_DESCRIPTION}
        |
        |#{if defined?(Rails)
             "[rails]\nversion: #{Rails::VERSION::STRING}"
           elsif defined?(Sinatra)
             "[sinatra]\nversion: #{Sinatra::VERSION}"
           end}
        |
        |[airbrake]
        |version: #{Airbrake::AIRBRAKE_VERSION}
        |
        |[airbrake-ruby]
        |version: #{Airbrake::Notice::NOTIFIER[:version]}
        |
        |[notifiers]
        |#{notifiers}
        |
        |The output above contains useful information about your environment. Our support
        |team may request this information if you have problems using the Airbrake gem;
        |we would be really grateful if you could attach the output to your message.
        |
        |The test exception was sent. Find it here: #{response['url']}
      OUTPUT
    end
  end

  desc 'Notify Airbrake of a new deploy'
  task :deploy do
    if defined?(Rails)
      initializer = Rails.root.join('config', 'initializers', 'airbrake.rb')

      # Avoid loading the environment to speed up the deploy task and try guess
      # the initializer file location.
      if initializer.exist?
        load initializer
      else
        Rake::Task[:environment].invoke
      end
    end

    Airbrake.create_deploy(
      environment: ENV['ENVIRONMENT'],
      username: ENV['USERNAME'],
      revision: ENV['REVISION'],
      repository: ENV['REPOSITORY'],
      version: ENV['VERSION']
    )
  end

  desc 'Install a Heroku deploy hook to notify Airbrake of deploys'
  task :install_heroku_deploy_hook do
    app = ENV['HEROKU_APP']

    config = Bundler.with_clean_env do
      `heroku config --shell#{ " --app #{app}" if app }`
    end

    heroku_env = config.each_line.with_object({}) do |line, h|
      h.merge!(Hash[*line.rstrip.split("\n").flat_map { |v| v.split('=', 2) }])
    end

    id = heroku_env['AIRBRAKE_PROJECT_ID']
    key = heroku_env['AIRBRAKE_API_KEY']

    exit!(1) if [id, key].any?(&:nil?)

    unless (env = heroku_env['RAILS_ENV'])
      env = 'production'
      puts "Airbrake couldn't identify your app's environment, so the '#{env}'" \
           " environment will be used."
    end

    url = "https://airbrake.io/api/v3/projects/#{id}/heroku-deploys?key=#{key}"
    url << "&environment=#{env}"

    command = %(heroku addons:create deployhooks:http --url="#{url}")
    command << " --app #{app}" if app

    puts "$ #{command}"
    Bundler.with_clean_env { puts `#{command}` }
  end
end
