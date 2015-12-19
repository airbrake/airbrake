# Gems from the gemspec.
require 'webmock'
require 'webmock/rspec'
require 'rspec/wait'
require 'pry'
require 'rack'
require 'rack/test'
require 'rake'

if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('2.0')
  require 'sidekiq'
  require 'sidekiq/cli'
end

require 'airbrake'
require 'airbrake/rake/tasks'

# Load integration tests only when they're run through appraisals.
if ENV['APPRAISAL_INITIALIZED']
  # Gems from appraisals that every application uses.
  require 'warden'

  # Load a Rails app or skip.
  begin
    ENV['RAILS_ENV'] = 'test'

    if RUBY_ENGINE == 'jruby'
      require 'activerecord-jdbcsqlite3-adapter'
    else
      require 'sqlite3'
    end

    require 'rails'

    rails_vsn = Gem::Version.new(Rails.version)

    if rails_vsn <= Gem::Version.new('4.2')
      ENV['DATABASE_URL'] = 'sqlite3:///:memory:'
    else
      ENV['DATABASE_URL'] = 'sqlite3::memory:'
    end

    require 'action_controller'
    require 'action_view'
    require 'action_view/testing/resolvers'
    require 'active_record/railtie'
    if rails_vsn >= Gem::Version.new('4.2')
      require 'active_job'

      # Silence logger.
      ActiveJob::Base.logger.level = 99
    end

    require 'resque'
    require 'resque_spec'
    require 'airbrake/resque/failure'
    Resque::Failure.backend = Resque::Failure::Airbrake

    require 'delayed_job'
    require 'delayed_job_active_record'
    require 'airbrake/delayed_job/plugin'
    Delayed::Worker.delay_jobs = false

    require 'airbrake/rails/railtie'

    load 'apps/rails/dummy_task.rake'
    require 'apps/rails/dummy_app'
  rescue LoadError
    puts '** Skipped Rails specs'
  end

  # Load a Sinatra app or skip.
  begin
    # Resque depends on Sinatra, so when we launch Rails specs, we also
    # accidentally load Sinatra.
    raise LoadError if defined?(Resque)

    require 'sinatra'
    require 'apps/sinatra/dummy_app'
  rescue LoadError
    puts '** Skipped Sinatra specs'
  end

  # Load a Rack app or skip.
  begin
    require 'apps/rack/dummy_app'
  rescue LoadError
    puts '** Skipped Rack specs'
  end
end

RSpec.configure do |c|
  c.order = 'random'
  c.color = true
  c.disable_monkey_patching!
  c.wait_timeout = 3

  c.include Rack::Test::Methods
end

Airbrake.configure do |c|
  c.project_id = 113743
  c.project_key = 'fd04e13d806a90f96614ad8e529b2822'
  c.logger = Logger.new('/dev/null')
  c.app_version = '1.2.3'
  c.workers = 5
end

# Make sure tests that use async requests fail.
Thread.abort_on_exception = true

AirbrakeTestError = Class.new(StandardError)

# Print header with versions information. This simplifies debugging of build
# failures on CircleCI.
versions = <<EOS
#{'#' * 80}
# RUBY_VERSION: #{RUBY_VERSION}
# RUBY_ENGINE: #{RUBY_ENGINE}
EOS
versions << "# JRUBY_VERSION #{JRUBY_VERSION}\n" if defined?(JRUBY_VERSION)
versions << "# Rails version: #{Rails.version}\n" if defined?(Rails)
versions << "# Sinatra version: #{Sinatra::VERSION}\n" if defined?(Sinatra)
versions << "# Rack release: #{Rack.release}\n"
versions << '#' * 80

puts versions
