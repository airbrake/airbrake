require File.expand_path(File.dirname(__FILE__) + "/lib/insert_commands.rb")
require File.expand_path(File.dirname(__FILE__) + "/lib/rake_commands.rb")

class AirbrakeGenerator < Rails::Generator::Base
  def add_options!(opt)
    opt.on('-k', '--api-key=key', String, "Your Airbrake API key")                                               { |v| options[:api_key] = v}
    opt.on('-h', '--heroku',              "Use the Heroku addon to provide your Airbrake API key")               { |v| options[:heroku]  = v}
    opt.on('-a', '--app=myapp', String,   "Your Heroku app name (only required if deploying to >1 Heroku app)") { |v| options[:app]     = v}
  end

  def manifest
    if !api_key_configured? && !options[:api_key] && !options[:heroku]
      puts "Must pass --api-key or --heroku or create config/initializers/airbrake.rb"
      exit
    end
    if plugin_is_present?
      puts "You must first remove the airbrake plugin. Please run: script/plugin remove airbrake"
      exit
    end
    record do |m|
      m.directory 'lib/tasks'
      m.file 'airbrake_tasks.rake', 'lib/tasks/airbrake_tasks.rake'
      if ['config/deploy.rb', 'Capfile'].all? { |file| File.exists?(file) }
        m.append_to 'config/deploy.rb', capistrano_hook
      end
      if api_key_expression
        if use_initializer?
          m.template 'initializer.rb', 'config/initializers/airbrake.rb',
            :assigns => {:api_key => api_key_expression}
        else
          m.template 'initializer.rb', 'config/airbrake.rb',
            :assigns => {:api_key => api_key_expression}
          m.append_to 'config/environment.rb', "require 'config/airbrake'"
        end
      end
      determine_api_key if heroku?
      m.rake "airbrake:test", :generate_only => true
    end
  end

  def api_key_expression
    s = if options[:api_key]
      "'#{options[:api_key]}'"
    elsif options[:heroku]
      "ENV['HOPTOAD_API_KEY']"
    end
  end

  def determine_api_key
    puts "Attempting to determine your API Key from Heroku..."
    ENV['HOPTOAD_API_KEY'] = heroku_api_key
    if ENV['HOPTOAD_API_KEY'] =~ /\S/
      puts "... Done."
      puts "Heroku's Airbrake API Key is '#{ENV['HOPTOAD_API_KEY']}'"
    else
      puts "... Failed."
      puts "WARNING: We were unable to detect the Airbrake API Key from your Heroku environment."
      puts "Your Heroku application environment may not be configured correctly."
      exit 1
    end
  end

  def heroku_var(var,app_name = nil)
    app = app_name ? "--app #{app_name}" : ''
    `heroku config #{app} | grep -E "#{var.upcase}" | awk '{ print $3; }'`.strip
  end

  def heroku_api_key
    heroku_var("(hoptoad|airbrake)_api_key",options[:app]).split.find {|x| x =~ /\S/ }
  end

  def heroku?
    options[:heroku] ||
      system("grep HOPTOAD_API_KEY config/initializers/airbrake.rb") ||
      system("grep HOPTOAD_API_KEY config/environment.rb")
  end

  def use_initializer?
    Rails::VERSION::MAJOR > 1
  end

  def api_key_configured?
    File.exists?('config/initializers/airbrake.rb') ||
      system("grep Airbrake config/environment.rb")
  end

  def capistrano_hook
    IO.read(source_path('capistrano_hook.rb'))
  end

  def plugin_is_present?
    File.exists?('vendor/plugins/airbrake')
  end
end
