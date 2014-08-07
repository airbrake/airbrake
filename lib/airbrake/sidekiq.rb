require 'sidekiq'

if ::Sidekiq::VERSION >= '3'
  ::Sidekiq.configure_server do |config|
    config.error_handlers << lambda do |exception, context|
      Airbrake.notify_or_ignore(exception, :parameters => context)
    end
  end
end