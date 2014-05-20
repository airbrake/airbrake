begin
  require "girl_friday"
rescue LoadError
end

begin
  require "sucker_punch"
rescue LoadError
end

require 'net/http'
require 'net/https'
require 'rubygems'
require 'logger'

require 'airbrake/version'
require 'airbrake/jobs/send_job'
require 'airbrake/utils/rack_filters'
require 'airbrake/utils/params_cleaner'
require 'airbrake/configuration'
require 'airbrake/notice'
require 'airbrake/sender'
require 'airbrake/response'
require 'airbrake/backtrace'
require 'airbrake/rack'
require 'airbrake/sinatra'
require 'airbrake/user_informer'

require 'airbrake/railtie' if defined?(Rails::Railtie)

module Airbrake
  API_VERSION = "2.4"
  LOG_PREFIX = "** [Airbrake] "

  class << self
    # The sender object is responsible for delivering formatted data to the Airbrake server.
    # Must respond to #send_to_airbrake. See Airbrake::Sender.
    attr_accessor :sender

    # A Airbrake configuration object. Must act like a hash and return sensible
    # values for all Airbrake configuration options. See Airbrake::Configuration.
    attr_writer :configuration

    # Tell the log that the Notifier is good to go
    def report_ready
      write_verbose_log("Notifier #{VERSION} ready to catch errors")
    end

    # Prints out the environment info to the log for debugging help
    def report_environment_info
      write_verbose_log("Environment Info: #{environment_info}")
    end

    # Prints out the response body from Airbrake for debugging help
    def report_response_body(response)
      write_verbose_log("Response from Airbrake: \n#{Response.pretty_format(response)}")
    end

    # Prints out the details about the notice that wasn't sent to server
    def report_notice(notice)
      write_verbose_log("Notice details: \n#{notice}")
    end

    def report_notice_not_sent_for_configuration
      write_verbose_log("Notice was not sent due to configuration: \
        \n  Environment Monitored? #{configuration.public?} \
        \n  API key set? #{configuration.configured?}")
    end

    # Returns the Ruby version, Rails version, and current Rails environment
    def environment_info
      info = "[Ruby: #{RUBY_VERSION}]"
      info << " [#{configuration.framework}]" if configuration.framework
      info << " [Env: #{configuration.environment_name}]" if configuration.environment_name
      info
    end

    # Writes out the given message to the #logger
    def write_verbose_log(message)
      logger.debug LOG_PREFIX + message if logger
    end

    # Look for the Rails logger currently defined
    def logger
      self.configuration.logger ||
        Logger.new(nil)
    end

    # Call this method to modify defaults in your initializers.
    #
    # @example
    #   Airbrake.configure do |config|
    #     config.api_key = '1234567890abcdef'
    #     config.secure  = false
    #   end
    def configure(silent = false)
      yield(configuration)
      self.sender = if configuration.test_mode?
                      CollectingSender.new(configuration)
                    else
                      Sender.new(configuration)
                    end

      report_ready unless silent
      self.sender
    end

    # The configuration object.
    # @see Airbrake.configure
    def configuration
      @configuration ||= Configuration.new
    end

    # Sends an exception manually using this method, even when you are not in a controller.
    #
    # @param [Exception] exception The exception you want to notify Airbrake about.
    # @param [Hash] opts Data that will be sent to Airbrake.
    #
    # @option opts [String] :api_key The API key for this project. The API key is a unique identifier that Airbrake uses for identification.
    # @option opts [String] :error_message The error returned by the exception (or the message you want to log).
    # @option opts [String] :backtrace A backtrace, usually obtained with +caller+.
    # @option opts [String] :rack_env The Rack environment.
    # @option opts [String] :session The contents of the user's session.
    # @option opts [String] :environment_name The application environment name.
    def notify(exception, opts = {})
      send_notice(build_notice_for(exception, opts))
    end

    # Sends the notice unless it is one of the default ignored exceptions
    # @see Airbrake.notify
    def notify_or_ignore(exception, opts = {})
      notice = build_notice_for(exception, opts)
      send_notice(notice) unless notice.ignore?
    end

    def build_lookup_hash_for(exception, options = {})
      notice = build_notice_for(exception, options)

      result = {}
      result[:action]           = notice.action      rescue nil
      result[:component]        = notice.component   rescue nil
      result[:error_class]      = notice.error_class if notice.error_class
      result[:environment_name] = 'production'

      unless notice.backtrace.lines.empty?
        result[:file]        = notice.backtrace.lines.first.file
        result[:line_number] = notice.backtrace.lines.first.number
      end

      result
    end

    private

    def send_notice(notice)
      if configuration.configured? && configuration.public?
        if configuration.async?
          configuration.async.call(notice)
          nil # make sure we never set env["airbrake.error_id"] for async notices
        else
          sender.send_to_airbrake(notice)
        end
      else
        report_notice_not_sent_for_configuration
      end
    end

    def build_notice_for(exception, opts = {})
      exception = unwrap_exception(exception)
      opts = opts.merge(:exception => exception) if exception.is_a?(Exception)
      opts = opts.merge(exception.to_hash) if exception.respond_to?(:to_hash)
      Notice.new(configuration.merge(opts))
    end

    def unwrap_exception(exception)
      if exception.respond_to?(:original_exception)
        exception.original_exception
      elsif exception.respond_to?(:continued_exception)
        exception.continued_exception
      else
        exception
      end
    end
  end
end
