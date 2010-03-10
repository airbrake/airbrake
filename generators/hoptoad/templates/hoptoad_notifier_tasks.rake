# Don't load anything when running the gems:* tasks.
# Otherwise, hoptoad_notifier will be considered a framework gem.
# https://thoughtbot.lighthouseapp.com/projects/14221/tickets/629
unless ARGV.any? {|a| a =~ /^gems/} 

  Dir[File.join(RAILS_ROOT, 'vendor', 'gems', 'hoptoad_notifier-*')].each do |vendored_notifier|
    $: << File.join(vendored_notifier, 'lib')
  end

  require 'hoptoad_notifier/tasks'

end
