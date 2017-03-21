require 'shellwords'
require 'English'

# Core library that sends notices.
# See: https://github.com/airbrake/airbrake-ruby
require 'airbrake-ruby'

require 'airbrake/version'

# Automatically load needed files for the environment the library is running in.
if defined?(Rack)
  require 'airbrake/rack/user'
  require 'airbrake/rack/context_filter'
  require 'airbrake/rack/session_filter'
  require 'airbrake/rack/http_params_filter'
  require 'airbrake/rack/http_headers_filter'
  require 'airbrake/rack/request_body_filter'
  require 'airbrake/rack/middleware'

  require 'airbrake/rails/railtie' if defined?(Rails)
end

require 'airbrake/rake/task_ext' if defined?(Rake::Task)
require 'airbrake/resque/failure' if defined?(Resque)
require 'airbrake/sidekiq/error_handler' if defined?(Sidekiq)
require 'airbrake/shoryuken/error_handler' if defined?(Shoryuken)
require 'airbrake/delayed_job/plugin' if defined?(Delayed)

require 'airbrake/logger/airbrake_logger'

# Notify of unhandled exceptions, if there were any, but ignore SystemExit.
at_exit do
  Airbrake.notify_sync($ERROR_INFO) if $ERROR_INFO
  Airbrake.close
end
