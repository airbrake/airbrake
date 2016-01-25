appraise 'rails-3.2' do
  gem 'rails', '~> 3.2.22'
  gem 'warden', '~> 1.2.3'

  gem 'activerecord-jdbcsqlite3-adapter', '~> 1.3.18', platforms: :jruby
  gem 'sqlite3', '~> 1.3.11', platforms: [:mri, :rbx]

  gem 'resque', '~> 1.25.2'
  gem 'resque_spec', git: 'git@github.com:kyrylo/resque_spec.git'

  gem 'delayed_job_active_record', '~> 4.1.0'
end

appraise 'rails-4.0' do
  gem 'rails', '~> 4.0.13'
  gem 'warden', '~> 1.2.3'

  gem 'activerecord-jdbcsqlite3-adapter', '~> 1.3.18', platforms: :jruby
  gem 'sqlite3', '~> 1.3.11', platforms: [:mri, :rbx]

  gem 'resque', '~> 1.25.2'
  gem 'resque_spec', git: 'git@github.com:kyrylo/resque_spec.git'

  gem 'delayed_job_active_record', '~> 4.1.0'
end

appraise 'rails-4.1' do
  gem 'rails', '~> 4.1.13'
  gem 'warden', '~> 1.2.3'

  gem 'activerecord-jdbcsqlite3-adapter', '~> 1.3.18', platforms: :jruby
  gem 'sqlite3', '~> 1.3.11', platforms: [:mri, :rbx]

  gem 'resque', '~> 1.25.2'
  gem 'resque_spec', git: 'git@github.com:kyrylo/resque_spec.git'

  gem 'delayed_job_active_record', '~> 4.1.0'
end

appraise 'rails-4.2' do
  gem 'rails', '~> 4.2.4'
  gem 'warden', '~> 1.2.3'

  gem 'activerecord-jdbcsqlite3-adapter', '~> 1.3.18', platforms: :jruby
  gem 'sqlite3', '~> 1.3.11', platforms: [:mri, :rbx]

  gem 'resque', '~> 1.25.2'
  gem 'resque_spec', git: 'git@github.com:kyrylo/resque_spec.git'

  gem 'delayed_job_active_record', '~> 4.1.0'
end

# Rails 5+ supports only Ruby 2.1+
if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('2.0')
  appraise 'rails-edge' do
    gem 'rails', github: 'rails/rails'
    gem 'arel', github: 'rails/arel'
    gem 'rack', github: 'rack/rack'
    gem 'warden', '~> 1.2.3'

    gem 'activerecord-jdbcsqlite3-adapter', '~> 1.3.18', platforms: :jruby
    gem 'sqlite3', '~> 1.3.11', platforms: [:mri, :rbx]

    gem 'resque', '~> 1.25.2'
    # A temporary fork of https://github.com/leshill/resque_spec with
    # https://github.com/leshill/resque_spec/pull/88 merged in. This allows us
    # to test our Resque integration.
    gem 'resque_spec', git: 'git@github.com:kyrylo/resque_spec.git'

    gem 'delayed_job_active_record', '~> 4.1.0'
  end
end

appraise 'sinatra' do
  gem 'sinatra', '~> 1.4.6'
  gem 'rack-test', '~> 0.6.3'
  gem 'warden', '~> 1.2.3'
end

appraise 'rack' do
  gem 'warden', '~> 1.2.3'
end
