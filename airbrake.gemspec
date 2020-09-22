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
frameworks as Rails, Sinatra, Resque, Sidekiq, Delayed Job, Shoryuken,
ActiveJob and many more.
DESC
  s.author      = 'Airbrake Technologies, Inc.'
  s.email       = 'support@airbrake.io'
  s.homepage    = 'https://airbrake.io'
  s.license     = 'MIT'

  s.require_path = 'lib'
  s.files        = ['lib/airbrake.rb', *Dir.glob('lib/**/*')]

  s.required_ruby_version = '>= 2.3'

  s.add_dependency 'airbrake-ruby', '~> 5.0'

  s.add_development_dependency 'rspec', '~> 3'
  s.add_development_dependency 'rspec-wait', '~> 0'
  s.add_development_dependency 'rake', '~> 12'
  s.add_development_dependency 'pry', '~> 0'
  s.add_development_dependency 'appraisal'
  s.add_development_dependency 'rack', '~> 2'
  s.add_development_dependency 'webmock', '~> 3'
  s.add_development_dependency 'amq-protocol'
  s.add_development_dependency 'sneakers', '~> 2'
  s.add_development_dependency 'rack-test', '= 0.6.3'
  s.add_development_dependency 'redis', '= 3.3.3'
  s.add_development_dependency 'sidekiq', '~> 5'
  s.add_development_dependency 'curb', '~> 0.9' if RUBY_ENGINE == 'ruby'
  s.add_development_dependency 'excon', '~> 0.64'
  s.add_development_dependency 'http', '~> 2.2'
  s.add_development_dependency 'httpclient', '~> 2.8'
  s.add_development_dependency 'typhoeus', '~> 1.3'
  s.add_development_dependency 'sqlite3', '~> 1.4' if RUBY_ENGINE == 'ruby'

  # Fixes build failure with public_suffix v3
  # https://circleci.com/gh/airbrake/airbrake-ruby/889
  s.add_development_dependency 'public_suffix', '~> 2.0', '< 3.0'

  # redis-namespace > 1.6.0 wants Ruby >= 2.4.
  s.add_development_dependency 'redis-namespace', '= 1.6.0'
end
