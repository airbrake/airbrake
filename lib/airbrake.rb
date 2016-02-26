require 'shellwords'

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
# This module extends original module Airbrake from airbrake-ruby and
# serves as a namespace for other classes and modules.
module Airbrake
  class << self
    ##
    # Allows users to add their own notice's builders. Useful if it's needed to
    # attach some info from the rack environment or request to the notice.
    #
    # @example Adds remote ip from the rack_env to the notice
    #   Airbrake.add_rack_builder |notice, request| do
    #     notice[:params][:remoteIp] = request.env['REMOTE_IP']
    #   end
    #
    # @yieldparam notice [Airbrake::Notice] notice that will be sent to the Airbrake
    # @yieldparam request [Rack::Request] current rack request
    def add_rack_builder(&block)
      Airbrake::Rack::NoticeBuilder.add_builder(&block)
    end
  end
end
