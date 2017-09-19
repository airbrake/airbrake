# Gems from the gemspec.
require 'webmock'
require 'webmock/rspec'
require 'rspec/wait'
require 'rack'
require 'rack/test'
require 'rake'
require 'pry'

require 'airbrake'
require 'airbrake/rake/tasks'

Airbrake.configure do |c|
  c.project_id = 113743
  c.project_key = 'fd04e13d806a90f96614ad8e529b2822'
  c.logger = Logger.new('/dev/null')
  c.app_version = '1.2.3'
  c.workers = 5
end

RSpec.configure do |c|
  c.order = 'random'
  c.color = true
  c.disable_monkey_patching!
  c.wait_timeout = 3

  c.include Rack::Test::Methods
end

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

    ENV['DATABASE_URL'] = if rails_vsn <= Gem::Version.new('4.2')
                            'sqlite3:///:memory:'
                          else
                            'sqlite3::memory:'
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
    require 'airbrake/resque'
    Resque::Failure.backend = Resque::Failure::Airbrake

    require 'delayed_job'
    require 'delayed_job_active_record'
    require 'airbrake/delayed_job'
    Delayed::Worker.delay_jobs = false

    require 'airbrake/rails'

    load 'apps/rails/dummy_task.rake'
    require 'apps/rails/dummy_app'
  rescue LoadError
    puts '** Skipped Rails specs'
  end

  # Load a Rack app or skip.
  begin
    # Don't load the Rack app since we want to test Sinatra if it's loaded.
    raise LoadError if defined?(Sinatra)

    require 'apps/rack/dummy_app'
  rescue LoadError
    puts '** Skipped Rack specs'
  end
end

# Make sure tests that use async requests fail.
Thread.abort_on_exception = true

AirbrakeTestError = Class.new(StandardError)

# Print header with versions information. This simplifies debugging of build
# failures on CircleCI.
versions = <<BANNER
#{'#' * 80}
# RUBY_VERSION: #{RUBY_VERSION}
# RUBY_ENGINE: #{RUBY_ENGINE}
BANNER
versions << "# JRUBY_VERSION #{JRUBY_VERSION}\n" if defined?(JRUBY_VERSION)
versions << "# Rails version: #{Rails.version}\n" if defined?(Rails)
versions << "# Rack release: #{Rack.release}\n"
versions << '#' * 80

puts versions
