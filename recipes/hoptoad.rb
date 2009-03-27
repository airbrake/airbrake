# When Hoptoad is installed as a plugin this is loaded automatically.
#
# When Hoptoad installed as a gem, you need to add 
#  require 'hoptoad_notifier/recipes/hoptoad'
# to your deploy.rb
#
# Defines deploy:notify_hoptoad which will send information about the deploy to Hoptoad.
#
after "deploy", "deploy:notify_hoptoad"

namespace :deploy do
  desc "Notify Hoptoad of the deployment"
  task :notify_hoptoad, :roles => :app do
    rake = fetch(:rake, "rake")
    rails_env = fetch(:rails_env, "production")
    run "cd #{current_release}; #{rake} RAILS_ENV=#{rails_env} hoptoad:deploy TO=#{rails_env} REVISION=#{current_revision} REPO=#{repository}"
  end
end
