require 'net/http'
require 'net/https'
require 'rubygems'
require 'active_support'
require 'hoptoad_notifier/configuration'
require 'hoptoad_notifier/notice'
require 'hoptoad_notifier/sender'
require 'hoptoad_notifier/catcher'
require 'hoptoad_notifier/backtrace'

# Plugin for applications to automatically post errors to the Hoptoad of their choice.
module HoptoadNotifier

  VERSION = "1.2.4"
  LOG_PREFIX = "** [Hoptoad] "

  HEADERS = {
    'Content-type'             => 'application/x-yaml',
    'Accept'                   => 'text/xml, application/xml',
    'X-Hoptoad-Client-Name'    => 'Hoptoad Notifier',
    'X-Hoptoad-Client-Version' => VERSION
  }

  class << self
    # (Internal)
    # The sender object is responsible for delivering formatted data to the Hoptoad server.
    # Must respond to #send_to_hoptoad. See HoptoadNotifier::Sender.
    attr_accessor :sender

    # (Internal)
    # A Hoptoad configuration object. Must act like a hash and return sensible
    # values for all Hoptoad configuration options. See
    # HoptoadNotifier::Configuration.
    attr_accessor :configuration

    def report_ready
      write_verbose_log("Notifier #{VERSION} ready to catch errors")
    end

    def report_environment_info
      write_verbose_log("Environment Info: #{environment_info}")
    end

    def report_response_body(response)
      write_verbose_log("Response from Hoptoad: \n#{response}")
    end

    def environment_info
      info = "[Ruby: #{RUBY_VERSION}]"
      info << " [Rails: #{::Rails::VERSION::STRING}]" if defined?(Rails)
      info << " [Env: #{configuration.environment_name}]"
    end

    def write_verbose_log(message)
      logger.info LOG_PREFIX + message if logger
    end

    # Checking for the logger in hopes we can get rid of the ugly syntax someday
    def logger
      if defined?(Rails.logger)
        Rails.logger
      elsif defined?(RAILS_DEFAULT_LOGGER)
        RAILS_DEFAULT_LOGGER
      end
    end

    # Call this method to modify defaults in your initializers.
    #
    # HoptoadNotifier.configure do |config|
    #   config.api_key = '1234567890abcdef'
    #   config.secure  = false
    # end
    def configure
      self.configuration ||= Configuration.new
      yield(configuration)
      self.sender = Sender.new(configuration)
      report_ready
    end

    # You can send an exception manually using this method, even when you are not in a
    # controller. You can pass an exception or a hash that contains the attributes that
    # would be sent to Hoptoad:
    # * api_key: The API key for this project. The API key is a unique identifier that Hoptoad
    #   uses for identification.
    # * error_message: The error returned by the exception (or the message you want to log).
    # * backtrace: A backtrace, usually obtained with +caller+.
    # * request: The controller's request object.
    # * session: The contents of the user's session.
    # * environment: ENV merged with the contents of the request's environment.
    def notify(exception, opts = {})
      send_notice(build_notice_for(exception, opts))
    end

    def notify_or_ignore(exception, opts = {})
      notice = build_notice_for(exception, opts)
      send_notice(notice) unless notice.ignore?
    end

    private

    def send_notice(notice)
      if configuration.public?
        sender.send_to_hoptoad(notice.to_xml)
      end
    end

    def build_notice_for(exception, opts = {})
      if exception.respond_to?(:to_hash)
        opts = opts.merge(exception)
      else
        opts = opts.merge(:exception => exception)
      end
      Notice.new(configuration.merge(opts))
    end
  end
end

