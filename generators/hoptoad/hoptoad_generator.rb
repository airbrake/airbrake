require File.expand_path(File.dirname(__FILE__) + "/lib/insert_commands.rb")
require File.expand_path(File.dirname(__FILE__) + "/lib/rake_commands.rb")

class HoptoadGenerator < Rails::Generator::Base
  def add_options!(opt)
    opt.on('-k', '--api-key=key', String, "Your Hoptoad API key") {|v| options[:api_key] = v}
  end

  def manifest
    unless File.exists?('config/initializers/hoptoad.rb') || options[:api_key]
      puts "Must pass --api-key or create config/initializers/hoptoad.rb"
      exit
    end
    record do |m|
      m.directory 'lib/tasks'
      m.file 'hoptoad_notifier_tasks.rake', 'lib/tasks/hoptoad_notifier_tasks.rake'
      # if File.exists?('config/deploy.rb')
      #   m.insert_into 'config/deploy.rb', "require 'hoptoad_notifier/recipes/hoptoad'"
      # end
      unless options[:api_key].nil?
        m.template 'initializer.rb', 'config/initializers/hoptoad.rb',
          :assigns => {:api_key => options[:api_key]}
      end
      # m.rake "hoptoad:test", :generate_only => true
    end
  end
end
