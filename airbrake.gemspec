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
  s.test_files   = Dir.glob('spec/**/*')

  s.required_ruby_version = '>= 2.1'

  s.add_dependency 'airbrake-ruby', '~> 4.2'

  s.add_development_dependency 'rspec', '~> 3'
  s.add_development_dependency 'rspec-wait', '~> 0'
  s.add_development_dependency 'rake', '~> 12'
  s.add_development_dependency 'pry', '~> 0'
  s.add_development_dependency 'appraisal', '~> 2'
  s.add_development_dependency 'rack', '~> 1'
  s.add_development_dependency 'webmock', '~> 2'

  s.add_development_dependency 'sneakers', '~> 2'
  # We still support Ruby 2.1.0+, but sneakers 2 wants 2.2+.
  s.add_development_dependency 'amq-protocol', '= 2.2.0'

  s.add_development_dependency 'rack-test', '= 0.6.3'
  s.add_development_dependency 'redis', '= 3.3.3'

  # Fixes build failure with public_suffix v3
  # https://circleci.com/gh/airbrake/airbrake-ruby/889
  s.add_development_dependency 'public_suffix', '~> 2.0', '< 3.0'

  # Newer versions don't support Ruby 2.2.0 and lower.
  s.add_development_dependency 'nokogiri', '= 1.9.1'

  # Parallel above v1.13.0 doesn't support Ruby v2.1 and lower (and we do).
  s.add_development_dependency 'parallel', '= 1.13.0'

  if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('2.2.2')
    s.add_development_dependency 'sidekiq', '~> 5'
  end
end
