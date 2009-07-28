require 'net/http'
require 'net/https'
require 'rubygems'
require 'active_support'
require 'hoptoad_notifier/configuration'
require 'hoptoad_notifier/sender'

# Plugin for applications to automatically post errors to the Hoptoad of their choice.
module HoptoadNotifier

  IGNORE_DEFAULT = ['ActiveRecord::RecordNotFound',
                    'ActionController::RoutingError',
                    'ActionController::InvalidAuthenticityToken',
                    'CGI::Session::CookieStore::TamperedWithCookie',
                    'ActionController::UnknownAction']

  # Some of these don't exist for Rails 1.2.*, so we have to consider that.
  IGNORE_DEFAULT.map!{|e| eval(e) rescue nil }.compact!
  IGNORE_DEFAULT.freeze

  IGNORE_USER_AGENT_DEFAULT = []

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

    # Returns the list of errors that are being ignored. The array can be appended to.
    def ignore
      @ignore ||= (HoptoadNotifier::IGNORE_DEFAULT.dup)
      @ignore.flatten!
      @ignore
    end

    # Sets the list of ignored errors to only what is passed in here. This method
    # can be passed a single error or a list of errors.
    def ignore_only=(names)
      @ignore = [names].flatten
    end

    # Returns the list of user agents that are being ignored. The array can be appended to.
    def ignore_user_agent
      @ignore_user_agent ||= (HoptoadNotifier::IGNORE_USER_AGENT_DEFAULT.dup)
      @ignore_user_agent.flatten!
      @ignore_user_agent
    end

    # Sets the list of ignored user agents to only what is passed in here. This method
    # can be passed a single user agent or a list of user agents.
    def ignore_user_agent_only=(names)
      @ignore_user_agent = [names].flatten
    end

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
      info << " [Rails: #{::Rails::VERSION::STRING}] [RailsEnv: #{RAILS_ENV}]" if defined?(Rails)
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
    #
    # NOTE: secure connections are not yet supported.
    def configure
      new_configuration = Configuration.new
      yield new_configuration
      if defined?(ActionController::Base) && !ActionController::Base.include?(HoptoadNotifier::Catcher)
        ActionController::Base.send(:include, HoptoadNotifier::Catcher)
      end
      self.configuration = new_configuration
      self.sender = Sender.new(configuration)
      report_ready
    end

    def protocol #:nodoc:
      secure ? "https" : "http"
    end

    def default_notice_options #:nodoc:
      {
        :api_key       => configuration.api_key,
        :error_message => 'Notification',
        :backtrace     => caller,
        :request       => {},
        :session       => {},
        :environment   => ENV.to_hash
      }
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
    def notify(notice = {})
      DummySender.new.notify_hoptoad( notice )
    end
  end

  # Include this module in Controllers in which you want to be notified of errors.
  module Catcher

    def self.included(base) #:nodoc:
      if base.instance_methods.map(&:to_s).include? 'rescue_action_in_public' and !base.instance_methods.map(&:to_s).include? 'rescue_action_in_public_without_hoptoad'
        base.send(:alias_method, :rescue_action_in_public_without_hoptoad, :rescue_action_in_public)
        base.send(:alias_method, :rescue_action_in_public, :rescue_action_in_public_with_hoptoad)
        if base.respond_to?(:hide_action)
          base.hide_action(:notify_hoptoad, :inform_hoptoad)
        end
      end
    end

    # Overrides the rescue_action method in ActionController::Base, but does not inhibit
    # any custom processing that is defined with Rails 2's exception helpers.
    def rescue_action_in_public_with_hoptoad(exception)
      notify_hoptoad(exception) unless ignore?(exception) || ignore_user_agent?
      rescue_action_in_public_without_hoptoad(exception)
    end

    # This method should be used for sending manual notifications while you are still
    # inside the controller. Otherwise it works like HoptoadNotifier.notify.
    def notify_hoptoad(hash_or_exception)
      if public_environment?
        notice = normalize_notice(hash_or_exception)
        notice = clean_notice(notice)
        sender.send_to_hoptoad(:notice => notice)
      end
    end

    # Returns the default logger or a logger that prints to STDOUT. Necessary for manual
    # notifications outside of controllers.
    def logger
      ActiveRecord::Base.logger
    rescue
      @logger ||= Logger.new(STDERR)
    end

    private

    def sender # :nodoc:
      HoptoadNotifier.sender
    end

    def public_environment? #nodoc:
      defined?(RAILS_ENV) and !['development', 'test'].include?(RAILS_ENV)
    end

    def ignore?(exception) #:nodoc:
      ignore_these = HoptoadNotifier.ignore.flatten
      ignore_these.include?(exception.class) ||
        ignore_these.include?(exception.class.name) ||
        HoptoadNotifier.configuration.ignore_by_filters.
          find {|filter| filter.call(exception_to_data(exception))}
    end

    def ignore_user_agent? #:nodoc:
      # Rails 1.2.6 doesn't have request.user_agent, so check for it here
      user_agent = request.respond_to?(:user_agent) ? request.user_agent : request.env["HTTP_USER_AGENT"]
      HoptoadNotifier.ignore_user_agent.flatten.any? { |ua| ua === user_agent }
    end

    def exception_to_data(exception) #:nodoc:
      data = {
        :api_key       => HoptoadNotifier.configuration.api_key,
        :error_class   => exception.class.name,
        :error_message => "#{exception.class.name}: #{exception.message}",
        :backtrace     => exception.backtrace,
        :environment   => ENV.to_hash
      }

      if self.respond_to? :request
        data[:request] = {
          :params      => request.parameters.to_hash,
          :rails_root  => File.expand_path(RAILS_ROOT),
          :url         => "#{request.protocol}#{request.host}#{request.request_uri}"
        }
        data[:environment].merge!(request.env.to_hash)
      end

      if self.respond_to? :session
        data[:session] = {
          :key         => session.instance_variable_get("@session_id"),
          :data        => session.respond_to?(:to_hash) ?
                            session.to_hash :
                            session.instance_variable_get("@data")
        }
      end

      data
    end

    def normalize_notice(notice) #:nodoc:
      case notice
      when Hash
        HoptoadNotifier.default_notice_options.merge(notice)
      when Exception
        HoptoadNotifier.default_notice_options.merge(exception_to_data(notice))
      end
    end

    def clean_notice(notice) #:nodoc:
      notice[:backtrace] = clean_hoptoad_backtrace(notice[:backtrace])
      if notice[:request].is_a?(Hash) && notice[:request][:params].is_a?(Hash)
        notice[:request][:params] = filter_parameters(notice[:request][:params]) if respond_to?(:filter_parameters)
        notice[:request][:params] = clean_hoptoad_params(notice[:request][:params])
      end
      if notice[:environment].is_a?(Hash)
        notice[:environment] = filter_parameters(notice[:environment]) if respond_to?(:filter_parameters)
        notice[:environment] = clean_hoptoad_environment(notice[:environment])
      end
      clean_non_serializable_data(notice)
    end

    def clean_hoptoad_backtrace(backtrace) #:nodoc:
      if backtrace.to_a.size == 1
        backtrace = backtrace.to_a.first.split(/\n\s*/)
      end

      filtered = backtrace.to_a.map do |line|
        HoptoadNotifier.configuration.backtrace_filters.inject(line) do |line, proc|
          proc.call(line)
        end
      end

      filtered.compact
    end

    def clean_hoptoad_params(params) #:nodoc:
      params.each do |k, v|
        params[k] = "[FILTERED]" if HoptoadNotifier.configuration.params_filters.any? do |filter|
          k.to_s.match(/#{filter}/)
        end
      end
    end

    def clean_hoptoad_environment(env) #:nodoc:
      env.each do |k, v|
        env[k] = "[FILTERED]" if HoptoadNotifier.configuration.environment_filters.any? do |filter|
          k.to_s.match(/#{filter}/)
        end
      end
    end

    def clean_non_serializable_data(data) #:nodoc:
      case data
      when Hash
        data.inject({}) do |result, (key, value)|
          result.update(key => clean_non_serializable_data(value))
        end
      when Fixnum, Array, String, Bignum
        data
      else
        data.to_s
      end
    end

  end

  # A dummy class for sending notifications manually outside of a controller.
  class DummySender
    def rescue_action_in_public(exception)
    end

    include HoptoadNotifier::Catcher
  end
end

