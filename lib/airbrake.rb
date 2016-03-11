require 'shellwords'
require 'English'

# Core library that sends notices.
# See: https://github.com/airbrake/airbrake-ruby
require 'airbrake-ruby'

require 'airbrake/version'

# Automatically load needed files for the environment the library is running in.
if defined?(Rack)
  require 'airbrake/rack/user'
  require 'airbrake/rack/notice_builder'
  require 'airbrake/rack/middleware'

  require 'airbrake/rails/railtie' if defined?(Rails)
end

require 'airbrake/rake/task_ext' if defined?(Rake::Task)
require 'airbrake/resque/failure' if defined?(Resque)
require 'airbrake/sidekiq/error_handler' if defined?(Sidekiq)
require 'airbrake/delayed_job/plugin' if defined?(Delayed)

##
# This module reopens the original Airbrake module from airbrake-ruby and adds
# integration specific methods.
module Airbrake
  class << self
    ##
    # Attaches a callback (builder) that runs every time the Rack integration
    # reports an error. Can be used to attach additional data from the Rack
    # request.
    #
    # @example Adding remote IP from the Rack environment
    #   Airbrake.add_rack_builder do |notice, request|
    #     notice[:params][:remoteIp] = request.env['REMOTE_IP']
    #   end
    #
    # @yieldparam notice [Airbrake::Notice] notice that will be sent to Airbrake
    # @yieldparam request [Rack::Request] current rack request
    # @yieldreturn [void]
    # @return [void]
    # @since 5.1.0
    def add_rack_builder(&block)
      Airbrake::Rack::NoticeBuilder.add_builder(&block)
    end
  end
end

# Notify of unhandled exceptions, if there were any, but ignore SystemExit.
at_exit do
  Airbrake.notify_sync($ERROR_INFO) if $ERROR_INFO
end
