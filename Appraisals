appraise 'rails-3.2' do
  gem 'rails', '~> 3.2.22.5'
  gem 'warden', '~> 1.2.3'

  gem 'activerecord-jdbcsqlite3-adapter', '~> 1.3.18', platforms: :jruby
  gem 'sqlite3', '~> 1.3.11', platforms: %i[mri rbx]

  gem 'resque', '~> 1.25.2'
  gem 'resque_spec', github: 'airbrake/resque_spec'

  gem 'delayed_job_active_record', '~> 4.1.0'
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
    gem 'rails', '~> 5.0.7'
    gem 'warden', '~> 1.2.3'
    gem 'rack', '~> 2.0'

    gem 'activerecord-jdbcsqlite3-adapter', '~> 1.3.18', platforms: :jruby
    gem 'sqlite3', '~> 1.3.11', platforms: %i[mri rbx]

    gem 'resque', '~> 1.25.2'
    gem 'resque_spec', github: 'airbrake/resque_spec'

    gem 'delayed_job_active_record', '~> 4.1.0'

    gem 'mime-types', '~> 3.1'

    # i18n 2+ supports only Ruby 2.3+.
    gem 'i18n', '~> 1.5'
  end

  appraise 'rails-5.1' do
    gem 'rails', '~> 5.1.4'
    gem 'warden', '~> 1.2.6'
    gem 'rack', '~> 2.0'

    gem 'activerecord-jdbcsqlite3-adapter', '~> 51.0', platforms: :jruby
    gem 'sqlite3', '~> 1.3.11', platforms: %i[mri rbx]

    gem 'resque', '~> 1.26'
    gem 'resque_spec', github: 'airbrake/resque_spec'

    gem 'delayed_job', github: 'collectiveidea/delayed_job'
    gem 'delayed_job_active_record', '~> 4.1'

    gem 'mime-types', '~> 3.1'

    # i18n 2+ supports only Ruby 2.3+.
    gem 'i18n', '~> 1.5'
  end

  appraise 'rails-5.2' do
    gem 'rails', '~> 5.2.0'
    gem 'warden', '~> 1.2.6'
    gem 'rack', '~> 2.0'

    # The gem doesn't support Rails v5.2 yet.
    # gem 'activerecord-jdbcsqlite3-adapter', '~> 51.0', platforms: :jruby
    gem 'sqlite3', '~> 1.3.11', platforms: %i[mri rbx]

    gem 'resque', '~> 1.26'
    gem 'resque_spec', github: 'airbrake/resque_spec'

    gem 'delayed_job', github: 'collectiveidea/delayed_job'
    gem 'delayed_job_active_record', '~> 4.1'

    gem 'mime-types', '~> 3.1'

    # i18n 2+ supports only Ruby 2.3+.
    gem 'i18n', '~> 1.5'
  end
end

appraise 'sinatra' do
  gem 'sinatra', '~> 1.4.7'
  gem 'warden', '~> 1.2.6'
end

appraise 'rack' do
  gem 'warden', '~> 1.2.6'
end
