require File.expand_path(File.dirname(__FILE__) + "/lib/insert_commands.rb")
require File.expand_path(File.dirname(__FILE__) + "/lib/rake_commands.rb")

class HoptoadGenerator < Rails::Generator::Base
  def add_options!(opt)
    opt.on('-k', '--api-key=key', String, "Your Hoptoad API key") {|v| options[:api_key] = v}
  end

  def manifest
    record do |m|
      m.directory 'lib/tasks'
      m.file 'hoptoad_notifier_tasks.rake', 'lib/tasks/hoptoad_notifier_tasks.rake'
      if File.exists?('config/deploy.rb')
        m.insert_into 'config/deploy.rb', "require 'hoptoad_notifier/recipes/hoptoad'"
      end
      if File.exists?('app/controllers/application_controller.rb')
        m.insert_into 'app/controllers/application_controller.rb', 'include HoptoadNotifier::Catcher'
      elsif File.exists?('app/controllers/application.rb')
        m.insert_into 'app/controllers/application.rb', 'include HoptoadNotifier::Catcher'
      end
      unless options[:api_key].nil?
        m.template 'initializer.rb', 'config/initializers/hoptoad.rb',
          :assigns => {:api_key => options[:api_key]}
      end
      m.rake "hoptoad:test", :generate_only => true
    end
  end
end
