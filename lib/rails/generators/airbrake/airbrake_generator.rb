require 'rails/generators'

class AirbrakeGenerator < Rails::Generators::Base

  class_option :api_key, :aliases => "-k", :type => :string, :desc => "Your Airbrake API key"
  class_option :heroku, :aliases => "-h", :type => :boolean, :desc => "Use the Heroku addon to provide your Airbrake API key"
  class_option :app, :aliases => "-a", :type => :string, :desc => "Your Heroku app name (only required if deploying to >1 Heroku app)"

  def self.source_root
    @_airbrake_source_root ||= File.expand_path("../../../../../generators/airbrake/templates", __FILE__)
  end

  def install
    ensure_api_key_was_configured
    ensure_plugin_is_not_present
    append_capistrano_hook
    generate_initializer unless api_key_configured?
    determine_api_key if heroku?
    test_airbrake
  end

  private

  def ensure_api_key_was_configured
    if !options[:api_key] && !options[:heroku] && !api_key_configured?
      puts "Must pass --api-key or --heroku or create config/initializers/airbrake.rb"
      exit
    end
  end

  def ensure_plugin_is_not_present
    if plugin_is_present?
      puts "You must first remove the airbrake plugin. Please run: script/plugin remove airbrake"
      exit
    end
  end

  def append_capistrano_hook
    if File.exists?('config/deploy.rb') && File.exists?('Capfile')
      append_file('config/deploy.rb', <<-HOOK)

        require './config/boot'
        require 'airbrake/capistrano'
      HOOK
    end
  end

  def api_key_expression
    s = if options[:api_key]
      "'#{options[:api_key]}'"
    elsif options[:heroku]
      "ENV['AIRBRAKE_API_KEY']"
    end
  end

  def generate_initializer
    template 'initializer.rb', 'config/initializers/airbrake.rb'
  end

  def determine_api_key
    puts "Attempting to determine your API Key from Heroku..."
    ENV['AIRBRAKE_API_KEY'] = heroku_api_key
    if ENV['AIRBRAKE_API_KEY'].blank?
      puts "... Failed."
      puts "WARNING: We were unable to detect the Airbrake API Key from your Heroku environment."
      puts "Your Heroku application environment may not be configured correctly."
      puts "make sure you have installed the addon by running heroku addons:add airbrake"
      exit 1
    else
      puts "... Done."
      puts "Heroku's Airbrake API Key is '#{ENV['AIRBRAKE_API_KEY']}'"
    end
  end

  def heroku_var(var,app_name = nil)
    app = app_name ? "--app #{app_name}" : ''
    `heroku config #{app} | grep -E "#{var.upcase}" | awk '{ print $2; }'`.strip
  end

  def heroku_api_key
    heroku_var("(hoptoad|airbrake)_api_key",options[:app]).split.find {|x| x unless x.blank?}
  end

  def heroku?
    options[:heroku] ||
      system("grep AIRBRAKE_API_KEY config/initializers/airbrake.rb") ||
      system("grep AIRBRAKE_API_KEY config/environment.rb")
  end

  def api_key_configured?
    File.exists?('config/initializers/airbrake.rb')
  end

  def test_airbrake
    puts run("rake airbrake:test --trace")
  end

  def plugin_is_present?
    File.exists?('vendor/plugins/airbrake')
  end
end
