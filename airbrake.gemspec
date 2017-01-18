require './lib/airbrake/version'

Gem::Specification.new do |s|
  s.name        = 'airbrake'
  s.version     = Airbrake::AIRBRAKE_VERSION.dup
  s.date        = Time.now.strftime('%Y-%m-%d')
  s.summary     = <<SUMMARY
Airbrake is an online tool that provides robust exception tracking in any of
your Ruby applications.
SUMMARY
  s.description = <<DESC
Airbrake is an online tool that provides robust exception tracking in any of
your Ruby applications. In doing so, it allows you to easily review errors, tie
an error to an individual piece of code, and trace the cause back to recent
changes. The Airbrake dashboard provides easy categorization, searching, and
prioritization of exceptions so that when errors occur, your team can quickly
determine the root cause.

Additionally, this gem includes integrations with such popular libraries and
frameworks as Rails, Sinatra, Resque, Sidekiq, Delayed Job, ActiveJob and many
more.
DESC
  s.author      = 'Airbrake Technologies, Inc.'
  s.email       = 'support@airbrake.io'
  s.homepage    = 'https://airbrake.io'
  s.license     = 'MIT'

  s.require_path = 'lib'
  s.files        = ['lib/airbrake.rb', *Dir.glob('lib/**/*')]
  s.test_files   = Dir.glob('spec/**/*')

  s.required_ruby_version = '>= 2.0'

  s.add_dependency 'airbrake-ruby', '~> 1.6'

  s.add_development_dependency 'rspec', '~> 3'
  s.add_development_dependency 'rspec-wait', '~> 0'
  s.add_development_dependency 'rake', '~> 12'
  s.add_development_dependency 'pry', '~> 0'
  s.add_development_dependency 'appraisal', '~> 2'
  s.add_development_dependency 'rack', '~> 1'
  s.add_development_dependency 'webmock', '~> 2'

  # We still support Ruby 2.0.0+, but nokogiri 1.7.0+ doesn't.
  s.add_development_dependency 'nokogiri', '= 1.6.8.1'

  s.add_development_dependency 'rack-test', '~> 0'
  s.add_development_dependency 'sidekiq', '~> 4'
end
