require File.expand_path(File.dirname(__FILE__) + "/lib/insert_commands.rb")
require File.expand_path(File.dirname(__FILE__) + "/lib/rake_commands.rb")

class HoptoadGenerator < Rails::Generator::Base
  def add_options!(opt)
    opt.on('-k', '--api-key=key', String, "Your Hoptoad API key")                                 {|v| options[:api_key] = v}
    opt.on('-h', '--heroku',              "Use the Heroku addon to provide your Hoptoad API key") {|v| options[:heroku]  = v}
  end

  def manifest
    if !api_key_configured? && !options[:api_key] && !options[:heroku]
      puts "Must pass --api-key or --heroku or create config/initializers/hoptoad.rb"
      exit
    end
    if plugin_is_present?
      puts "You must first remove the hoptoad_notifier plugin. Please run: script/plugin remove hoptoad_notifier"
      exit
    end
    record do |m|
      m.directory 'lib/tasks'
      m.file 'hoptoad_notifier_tasks.rake', 'lib/tasks/hoptoad_notifier_tasks.rake'
      if ['config/deploy.rb', 'Capfile'].all? { |file| File.exists?(file) }
        m.append_to 'config/deploy.rb', capistrano_hook
      end
      if api_key_expression
        if use_initializer?
          m.template 'initializer.rb', 'config/initializers/hoptoad.rb',
            :assigns => {:api_key => api_key_expression}
        else
          m.template 'initializer.rb', 'config/hoptoad.rb',
            :assigns => {:api_key => api_key_expression}
          m.append_to 'config/environment.rb', "require 'config/hoptoad'"
        end
      end
      m.rake "hoptoad:test", :generate_only => true
    end
  end

  def api_key_expression
    s = if options[:api_key]
      "'#{options[:api_key]}'"
    elsif options[:heroku]
      "ENV['HOPTOAD_API_KEY']"
    end
  end

  def use_initializer?
    Rails::VERSION::MAJOR > 1
  end

  def api_key_configured?
    File.exists?('config/initializers/hoptoad.rb') ||
      system("grep HoptoadNotifier config/environment.rb")
  end

  def capistrano_hook
    IO.read(source_path('capistrano_hook.rb'))
  end

  def plugin_is_present?
    File.exists?('vendor/plugins/hoptoad_notifier')
  end
end
