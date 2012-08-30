# Don't load anything when running the gems:* tasks.
# Otherwise, airbrake will be considered a framework gem.
# https://thoughtbot.lighthouseapp.com/projects/14221/tickets/629
unless ARGV.any? {|a| a =~ /^gems/}

  Dir[File.join(Rails.root, 'vendor', 'gems', 'airbrake-*')].each do |vendored_notifier|
    $: << File.join(vendored_notifier, 'lib')
  end

  begin
    require 'airbrake/tasks'
  rescue LoadError => exception
    namespace :airbrake do
      %w(deploy test log_stdout).each do |task_name|
        desc "Missing dependency for airbrake:#{task_name}"
        task task_name do
          $stderr.puts "Failed to run airbrake:#{task_name} because of missing dependency."
          $stderr.puts "You probably need to run `rake gems:install` to install the airbrake gem"
          abort exception.inspect
        end
      end
    end
  end

end
