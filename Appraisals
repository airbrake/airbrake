# frozen_string_literal: true

if Gem::Version.new(RUBY_VERSION) < Gem::Version.new('2.7.0') && RUBY_ENGINE != 'jruby'
  appraise 'rails-4.1' do
    gem 'rails', '~> 4.1.16'
    gem 'warden', '~> 1.2.3'

    gem 'activerecord-jdbcsqlite3-adapter', '~> 1.3.18', platforms: :jruby

    gem 'resque', '~> 1.25.2'
    gem 'resque_spec', github: 'airbrake/resque_spec'

    gem 'delayed_job_active_record', '~> 4.1.0'

    gem 'mime-types', '~> 3.1'
    gem 'sprockets', '~> 3.7'
    gem 'rack', '~> 1'
  end

  appraise 'rails-4.2' do
    gem 'rails', '~> 4.2.10'
    gem 'warden', '~> 1.2.3'

    gem 'activerecord-jdbcsqlite3-adapter', '~> 1.3.18', platforms: :jruby
    gem 'sqlite3', '~> 1.4', platforms: %i[mri rbx]

    gem 'resque', '~> 1.25.2'
    gem 'resque_spec', github: 'airbrake/resque_spec'

    gem 'delayed_job_active_record', '~> 4.1.0'

    gem 'mime-types', '~> 3.1'
    gem 'sprockets', '~> 3.7'
    gem 'rack', '~> 1'
  end
end

appraise 'rails-5.0' do
  gem 'rails', '~> 5.0.7'
  gem 'warden', '~> 1.2.3'

  gem 'activerecord-jdbcsqlite3-adapter', '~> 1.3.18', platforms: :jruby

  gem 'resque', '~> 1.25.2'
  gem 'resque_spec', github: 'airbrake/resque_spec'

  gem 'delayed_job_active_record', '~> 4.1.0'

  gem 'mime-types', '~> 3.1'
  gem 'sprockets', '~> 3.7'
end

appraise 'rails-5.1' do
  gem 'rails', '~> 5.1.4'
  gem 'warden', '~> 1.2.6'

  gem 'activerecord-jdbcsqlite3-adapter', '~> 51.0', platforms: :jruby

  gem 'resque', '~> 1.26'
  gem 'resque_spec', github: 'airbrake/resque_spec'

  gem 'delayed_job', github: 'collectiveidea/delayed_job'
  gem 'delayed_job_active_record', '~> 4.1'

  gem 'mime-types', '~> 3.1'
  gem 'sprockets', '~> 3.7'
end

appraise 'rails-5.2' do
  gem 'rails', '~> 5.2.0'
  gem 'warden', '~> 1.2.6'
  gem 'rack', '~> 2.0'

  gem 'activerecord-jdbcsqlite3-adapter', '~> 52.0', platforms: :jruby

  gem 'resque', '~> 1.26'
  gem 'resque_spec', github: 'airbrake/resque_spec'

  gem 'delayed_job', github: 'collectiveidea/delayed_job'
  gem 'delayed_job_active_record', '~> 4.1'

  gem 'mime-types', '~> 3.1'
end

# Rails 6.0+ supports only modern Rubies (2.5+)
if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('2.5')
  appraise 'rails-6.0' do
    gem 'rails', '~> 6.0.2'
    gem 'warden', '~> 1.2.6'
    gem 'rack', '~> 2.0'

    gem 'activerecord-jdbcsqlite3-adapter', '~> 60.1', platforms: :jruby

    gem 'resque', '~> 1.26'
    gem 'resque_spec', github: 'airbrake/resque_spec'

    gem 'delayed_job', github: 'collectiveidea/delayed_job'
    gem 'delayed_job_active_record', '~> 4.1'

    gem 'mime-types', '~> 3.1'
  end
end

appraise 'sinatra' do
  gem 'sinatra', '~> 2'
  gem 'warden', '~> 1.2.6'
end

appraise 'rack' do
  gem 'warden', '~> 1.2.6'
end
