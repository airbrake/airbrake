if defined?(ActionController::Base) && !ActionController::Base.include?(HoptoadNotifier::Catcher)
  ActionController::Base.send(:include, HoptoadNotifier::Catcher)
end

require File.join(File.dirname(__FILE__), '..', 'lib', 'hoptoad_notifier', 'rails_initializer')
HoptoadNotifier::RailsInitializer.initialize

HoptoadNotifier.configure(true) do |config|
  config.environment_name = RAILS_ENV
  config.project_root     = RAILS_ROOT
end
