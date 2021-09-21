# frozen_string_literal: true

appraise 'rails-5.2' do
  gem 'rails', '~> 5.2.0'
  gem 'warden', '~> 1.2.6'
  gem 'rack', '~> 2.0'

  gem 'activerecord-jdbcsqlite3-adapter', '~> 52.0', platforms: :jruby
  gem 'sqlite3', '~> 1.4', platforms: %i[mri rbx]

  gem 'resque', '~> 1.26'
  gem 'resque_spec', github: 'airbrake/resque_spec'

  gem 'delayed_job', github: 'collectiveidea/delayed_job'
  gem 'delayed_job_active_record', '~> 4.1'

  gem 'mime-types', '~> 3.1'
end

appraise 'rails-6.0' do
  gem 'rails', '~> 6.0.2'
  gem 'warden', '~> 1.2.6'
  gem 'rack', '~> 2.0'

  gem 'activerecord-jdbcsqlite3-adapter', '~> 60.1', platforms: :jruby
  gem 'sqlite3', '~> 1.4', platforms: %i[mri rbx]

  gem 'resque', '~> 1.26'
  gem 'resque_spec', github: 'airbrake/resque_spec'

  gem 'delayed_job', github: 'collectiveidea/delayed_job'
  gem 'delayed_job_active_record', '~> 4.1'

  gem 'mime-types', '~> 3.1'
end

appraise 'sinatra' do
  gem 'sinatra', '~> 2'
  gem 'warden', '~> 1.2.6'
end

appraise 'rack' do
  gem 'warden', '~> 1.2.6'
end
