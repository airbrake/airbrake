# Defines deploy:notify_airbrake which will send information about the deploy to Airbrake.

Capistrano::Configuration.instance(:must_exist).load do
  after "deploy",            "deploy:notify_airbrake"
  after "deploy:migrations", "deploy:notify_airbrake"

  namespace :deploy do
    desc "Notify Airbrake of the deployment"
    task :notify_airbrake, :except => { :no_release => true } do
      rails_env = fetch(:airbrake_env, fetch(:rails_env, "production"))
      local_user = ENV['USER'] || ENV['USERNAME']
      executable = RUBY_PLATFORM.downcase.include?('mswin') ? fetch(:rake, 'rake.bat') : fetch(:rake, 'rake')
      notify_command = "#{executable} airbrake:deploy TO=#{rails_env} REVISION=#{current_revision} REPO=#{repository} USER=#{local_user}"
      notify_command << " DRY_RUN=true" if dry_run
      notify_command << " API_KEY=#{ENV['API_KEY']}" if ENV['API_KEY']
      puts "Notifying Airbrake of Deploy (#{notify_command})"
      `#{notify_command}`
      puts "Airbrake Notification Complete."
    end
  end
end
