require './lib/airbrake/version'

Gem::Specification.new do |s|
  s.name        = 'airbrake'
  s.version     = Airbrake::AIRBRAKE_VERSION.dup
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

  s.required_ruby_version = '>= 2.6'

  s.metadata = {
    'rubygems_mfa_required' => 'true',
  }

  s.add_dependency 'airbrake-ruby', '~> 6.0'

  s.add_development_dependency 'rspec', '~> 3'
  s.add_development_dependency 'rspec-wait', '~> 0'
  s.add_development_dependency 'rake', '~> 13'
  s.add_development_dependency 'pry', '~> 0'
  s.add_development_dependency 'appraisal'
  s.add_development_dependency 'rack', '~> 2'
  s.add_development_dependency 'webmock', '~> 3'
  s.add_development_dependency 'amq-protocol'
  s.add_development_dependency 'rack-test', '~> 2.0'
  s.add_development_dependency 'redis', '~> 4.5'
  s.add_development_dependency 'sidekiq', '~> 6'
  s.add_development_dependency 'curb', '~> 1.0' if RUBY_ENGINE == 'ruby'
  s.add_development_dependency 'excon', '~> 0.64'
  s.add_development_dependency 'http', '~> 5.0'
  s.add_development_dependency 'httpclient', '~> 2.8'
  s.add_development_dependency 'typhoeus', '~> 1.3'

  # Fixes build failure with public_suffix v3
  # https://circleci.com/gh/airbrake/airbrake-ruby/889
  s.add_development_dependency 'public_suffix', '~> 4.0', '< 5.0'

  s.add_development_dependency 'redis-namespace', '~> 1.8'
end
