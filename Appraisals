# frozen_string_literal: true

# Rails 5 doesn't work on Ruby 3+.
if Gem::Version.new(RUBY_VERSION) < Gem::Version.new('3.0.0')
  appraise 'rails-5.2' do
    gem 'rails', '~> 5.2.0'
    gem 'warden', '~> 1.2.6'
    gem 'rack', '~> 2.0'

    gem 'activerecord-jdbcsqlite3-adapter', '~> 52.0', platforms: :jruby
    gem 'sqlite3', '~> 1.4', platforms: %i[mri rbx]

    gem 'resque', '~> 1.26'
    gem 'resque_spec', github: 'airbrake/resque_spec'

    gem 'delayed', '~> 0.4'

    gem 'mime-types', '~> 3.1'
  end
end

appraise 'rails-6.0' do
  gem 'rails', '~> 6.0.4.1'
  gem 'warden', '~> 1.2.6'
  gem 'rack', '~> 2.0'

  gem 'activerecord-jdbcsqlite3-adapter', '~> 60.1', platforms: :jruby
  gem 'sqlite3', '~> 1.4', platforms: %i[mri rbx]

  gem 'resque', '~> 1.26'
  gem 'resque_spec', github: 'airbrake/resque_spec'

  gem 'delayed', '~> 0.4'

  gem 'mime-types', '~> 3.1'
end

appraise 'rails-6.1' do
  gem 'rails', '~> 6.1.4.1'
  gem 'warden', '~> 1.2.6'
  gem 'rack', '~> 2.0'

  gem 'activerecord-jdbcsqlite3-adapter',
      github: 'jruby/activerecord-jdbc-adapter',
      branch: '61-stable',
      platforms: :jruby
  gem 'sqlite3', '~> 1.4', platforms: %i[mri rbx]

  gem 'resque', '~> 1.26'
  gem 'resque_spec', github: 'airbrake/resque_spec'

  gem 'delayed', '~> 0.4'

  gem 'mime-types', '~> 3.1'
end

if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('2.7.0')
  appraise 'rails-7.0' do
    gem 'rails', '~> 7.0.1'
    gem 'warden', '~> 1.2.6'
    gem 'rack', '~> 2.0'

    gem 'activerecord-jdbcsqlite3-adapter',
        github: 'jruby/activerecord-jdbc-adapter',
        branch: '61-stable',
        platforms: :jruby
    gem 'sqlite3', '~> 1.4', platforms: %i[mri rbx]

    gem 'resque', '~> 1.26'
    gem 'resque_spec', github: 'airbrake/resque_spec'

    gem 'delayed', '~> 0.4'

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
