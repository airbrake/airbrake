gem 'sidekiq', '~> 3.0'
require 'sidekiq'

Sidekiq.configure_server do |config|
  config.error_handlers << ->(exception, context)
    Airbrake.notify_or_ignore(exception, :parameters => context)
  end
end
