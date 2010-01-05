require File.expand_path(File.dirname(__FILE__) + "/lib/insert_commands.rb")

class HoptoadNotifierGenerator < Rails::Generator::Base
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
      m.readme 'README'
    end
  end
end
