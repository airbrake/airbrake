appraise 'rails-3.2' do
  gem 'rails', '~> 3.2.22.5'
  gem 'warden', '~> 1.2.3'

  gem 'activerecord-jdbcsqlite3-adapter', '~> 1.3.18', platforms: :jruby
  gem 'sqlite3', '~> 1.3.11', platforms: %i[mri rbx]

  gem 'resque', '~> 1.25.2'
  gem 'resque_spec', github: 'airbrake/resque_spec'

  gem 'delayed_job_active_record', '~> 4.1.0'
end

appraise 'rails-4.0' do
  gem 'rails', '~> 4.0.13'
  gem 'warden', '~> 1.2.3'

  gem 'activerecord-jdbcsqlite3-adapter', '~> 1.3.18', platforms: :jruby
  gem 'sqlite3', '~> 1.3.11', platforms: %i[mri rbx]

  gem 'resque', '~> 1.25.2'
  gem 'resque_spec', github: 'airbrake/resque_spec'

  gem 'delayed_job_active_record', '~> 4.1.0'

  gem 'mime-types', '~> 3.1'
end

appraise 'rails-4.1' do
  gem 'rails', '~> 4.1.16'
  gem 'warden', '~> 1.2.3'

  gem 'activerecord-jdbcsqlite3-adapter', '~> 1.3.18', platforms: :jruby
  gem 'sqlite3', '~> 1.3.11', platforms: %i[mri rbx]

  gem 'resque', '~> 1.25.2'
  gem 'resque_spec', github: 'airbrake/resque_spec'

  gem 'delayed_job_active_record', '~> 4.1.0'

  gem 'mime-types', '~> 3.1'
end

appraise 'rails-4.2' do
  gem 'rails', '~> 4.2.10'
  gem 'warden', '~> 1.2.3'

  gem 'activerecord-jdbcsqlite3-adapter', '~> 1.3.18', platforms: :jruby
  gem 'sqlite3', '~> 1.3.11', platforms: %i[mri rbx]

  gem 'resque', '~> 1.25.2'
  gem 'resque_spec', github: 'airbrake/resque_spec'

  gem 'delayed_job_active_record', '~> 4.1.0'

  gem 'mime-types', '~> 3.1'
end

# Rails 5+ supports only modern Rubies (2.2.2+)
if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('2.2.2')
  appraise 'rails-5.0' do
    gem 'rails', '~> 5.0.6'
    gem 'warden', '~> 1.2.6'
    gem 'rack', '~> 2.0'

    gem 'activerecord-jdbcsqlite3-adapter', '~> 1.3.20', platforms: :jruby
    gem 'sqlite3', '~> 1.3.11', platforms: %i[mri rbx]

    gem 'resque', '~> 1.26'
    gem 'resque_spec', github: 'airbrake/resque_spec'

    gem 'delayed_job_active_record', '~> 4.1.1'

    gem 'mime-types', '~> 3.1'
  end

  appraise 'rails-5.1' do
    gem 'rails', '~> 5.1.4'
    gem 'warden', '~> 1.2.6'
    gem 'rack', '~> 2.0'

    gem 'activerecord-jdbcsqlite3-adapter', '~> 1.3.20', platforms: :jruby
    gem 'sqlite3', '~> 1.3.11', platforms: %i[mri rbx]

    gem 'resque', '~> 1.26'
    gem 'resque_spec', github: 'airbrake/resque_spec'

    gem 'delayed_job', github: 'collectiveidea/delayed_job'
    gem 'delayed_job_active_record', github: 'collectiveidea/delayed_job_active_record'

    gem 'mime-types', '~> 3.1'
  end

  appraise 'rails-edge' do
    gem 'rails', github: 'rails/rails', branch: '5-2-stable'
    gem 'arel', github: 'rails/arel'
    gem 'rack', '~> 2.0'
    gem 'warden', '~> 1.2.6'

    gem 'activerecord-jdbcsqlite3-adapter', '~> 1.3.20', platforms: :jruby
    gem 'sqlite3', '~> 1.3.11', platforms: %i[mri rbx]

    gem 'resque', '~> 1.26'
    # A temporary fork of https://github.com/leshill/resque_spec with
    # https://github.com/leshill/resque_spec/pull/88 merged in. This allows us
    # to test our Resque integration.
    gem 'resque_spec', github: 'airbrake/resque_spec'

    gem 'delayed_job', github: 'collectiveidea/delayed_job'
    gem 'delayed_job_active_record', github: 'collectiveidea/delayed_job_active_record'
  end
end

appraise 'sinatra' do
  gem 'sinatra', '~> 1.4.7'
  gem 'warden', '~> 1.2.6'
end

appraise 'rack' do
  gem 'warden', '~> 1.2.6'
end
