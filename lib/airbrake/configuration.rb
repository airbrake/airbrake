module Airbrake
  # Used to set up and modify settings for the notifier.
  class Configuration

    OPTIONS = [:api_key, :backtrace_filters, :development_environments,
        :development_lookup, :environment_name, :host,
        :http_open_timeout, :http_read_timeout, :ignore, :ignore_by_filters,
        :ignore_user_agent, :notifier_name, :notifier_url, :notifier_version,
        :params_filters, :project_root, :port, :protocol, :proxy_host,
        :proxy_pass, :proxy_port, :proxy_user, :secure, :use_system_ssl_cert_chain, 
        :framework, :user_information, :rescue_rake_exceptions].freeze

    # The API key for your project, found on the project edit form.
    attr_accessor :api_key

    # The host to connect to (defaults to airbrake.io).
    attr_accessor :host

    # The port on which your Airbrake server runs (defaults to 443 for secure
    # connections, 80 for insecure connections).
    attr_accessor :port

    # +true+ for https connections, +false+ for http connections.
    attr_accessor :secure
    
    # +true+ to use whatever CAs OpenSSL has installed on your system. +false+ to use the ca-bundle.crt file included in Airbrake itself (reccomended and default)
    attr_accessor :use_system_ssl_cert_chain

    # The HTTP open timeout in seconds (defaults to 2).
    attr_accessor :http_open_timeout

    # The HTTP read timeout in seconds (defaults to 5).
    attr_accessor :http_read_timeout

    # The hostname of your proxy server (if using a proxy)
    attr_accessor :proxy_host

    # The port of your proxy server (if using a proxy)
    attr_accessor :proxy_port

    # The username to use when logging into your proxy server (if using a proxy)
    attr_accessor :proxy_user

    # The password to use when logging into your proxy server (if using a proxy)
    attr_accessor :proxy_pass

    # A list of parameters that should be filtered out of what is sent to Airbrake.
    # By default, all "password" attributes will have their contents replaced.
    attr_reader :params_filters

    # A list of filters for cleaning and pruning the backtrace. See #filter_backtrace.
    attr_reader :backtrace_filters

    # A list of filters for ignoring exceptions. See #ignore_by_filter.
    attr_reader :ignore_by_filters

    # A list of exception classes to ignore. The array can be appended to.
    attr_reader :ignore

    # A list of user agents that are being ignored. The array can be appended to.
    attr_reader :ignore_user_agent

    # A list of environments in which notifications should not be sent.
    attr_accessor :development_environments

    # +true+ if you want to check for production errors matching development errors, +false+ otherwise.
    attr_accessor :development_lookup

    # The name of the environment the application is running in
    attr_accessor :environment_name

    # The path to the project in which the error occurred, such as the RAILS_ROOT
    attr_accessor :project_root

    # The name of the notifier library being used to send notifications (such as "Airbrake Notifier")
    attr_accessor :notifier_name

    # The version of the notifier library being used to send notifications (such as "1.0.2")
    attr_accessor :notifier_version

    # The url of the notifier library being used to send notifications
    attr_accessor :notifier_url

    # The logger used by Airbrake
    attr_accessor :logger

    # The text that the placeholder is replaced with. {{error_id}} is the actual error number.
    attr_accessor :user_information

    # The framework Airbrake is configured to use
    attr_accessor :framework

    # Should Airbrake catch exceptions from Rake tasks?
    # (boolean or nil; set to nil to catch exceptions when rake isn't running from a terminal; default is nil)
    attr_accessor :rescue_rake_exceptions

    DEFAULT_PARAMS_FILTERS = %w(password password_confirmation).freeze

    DEFAULT_BACKTRACE_FILTERS = [
      lambda { |line|
        if defined?(Airbrake.configuration.project_root) && Airbrake.configuration.project_root.to_s != '' 
          line.sub(/#{Airbrake.configuration.project_root}/, "[PROJECT_ROOT]")
        else
          line
        end
      },
      lambda { |line| line.gsub(/^\.\//, "") },
      lambda { |line|
        if defined?(Gem)
          Gem.path.inject(line) do |line, path|
            line.gsub(/#{path}/, "[GEM_ROOT]")
          end
        end
      },
      lambda { |line| line if line !~ %r{lib/airbrake} }
    ].freeze

    IGNORE_DEFAULT = ['ActiveRecord::RecordNotFound',
                      'ActionController::RoutingError',
                      'ActionController::InvalidAuthenticityToken',
                      'CGI::Session::CookieStore::TamperedWithCookie',
                      'ActionController::UnknownAction',
                      'AbstractController::ActionNotFound',
                      'Mongoid::Errors::DocumentNotFound']

    alias_method :secure?, :secure
    alias_method :use_system_ssl_cert_chain?, :use_system_ssl_cert_chain

    def initialize
      @secure                   = false
      @use_system_ssl_cert_chain= false
      @host                     = 'airbrake.io'
      @http_open_timeout        = 2
      @http_read_timeout        = 5
      @params_filters           = DEFAULT_PARAMS_FILTERS.dup
      @backtrace_filters        = DEFAULT_BACKTRACE_FILTERS.dup
      @ignore_by_filters        = []
      @ignore                   = IGNORE_DEFAULT.dup
      @ignore_user_agent        = []
      @development_environments = %w(development test cucumber)
      @development_lookup       = true
      @notifier_name            = 'Airbrake Notifier'
      @notifier_version         = VERSION
      @notifier_url             = 'http://airbrake.io'
      @framework                = 'Standalone'
      @user_information         = 'Airbrake Error {{error_id}}'
      @rescue_rake_exceptions   = nil
    end

    # Takes a block and adds it to the list of backtrace filters. When the filters
    # run, the block will be handed each line of the backtrace and can modify
    # it as necessary.
    #
    # @example
    #   config.filter_bracktrace do |line|
    #     line.gsub(/^#{Rails.root}/, "[RAILS_ROOT]")
    #   end
    #
    # @param [Proc] block The new backtrace filter.
    # @yieldparam [String] line A line in the backtrace.
    def filter_backtrace(&block)
      self.backtrace_filters << block
    end

    # Takes a block and adds it to the list of ignore filters.
    # When the filters run, the block will be handed the exception.
    # @example
    #   config.ignore_by_filter do |exception_data|
    #     true if exception_data[:error_class] == "RuntimeError"
    #   end
    #
    # @param [Proc] block The new ignore filter
    # @yieldparam [Hash] data The exception data given to +Airbrake.notify+
    # @yieldreturn [Boolean] If the block returns true the exception will be ignored, otherwise it will be processed by airbrake.
    def ignore_by_filter(&block)
      self.ignore_by_filters << block
    end

    # Overrides the list of default ignored errors.
    #
    # @param [Array<Exception>] names A list of exceptions to ignore.
    def ignore_only=(names)
      @ignore = [names].flatten
    end

    # Overrides the list of default ignored user agents
    #
    # @param [Array<String>] A list of user agents to ignore
    def ignore_user_agent_only=(names)
      @ignore_user_agent = [names].flatten
    end

    # Allows config options to be read like a hash
    #
    # @param [Symbol] option Key for a given attribute
    def [](option)
      send(option)
    end

    # Returns a hash of all configurable options
    def to_hash
      OPTIONS.inject({}) do |hash, option|
        hash[option.to_sym] = self.send(option)
        hash
      end
    end

    # Returns a hash of all configurable options merged with +hash+
    #
    # @param [Hash] hash A set of configuration options that will take precedence over the defaults
    def merge(hash)
      to_hash.merge(hash)
    end

    # Determines if the notifier will send notices.
    # @return [Boolean] Returns +false+ if in a development environment, +true+ otherwise.
    def public?
      !development_environments.include?(environment_name)
    end

    def port
      @port || default_port
    end

    def protocol
      if secure?
        'https'
      else
        'http'
      end
    end

    def js_notifier=(*args)
      warn '[AIRBRAKE] config.js_notifier has been deprecated and has no effect.  You should use <%= airbrake_javascript_notifier %> directly at the top of your layouts.  Be sure to place it before all other javascript.'
    end

    def environment_filters
      warn 'config.environment_filters has been deprecated and has no effect.'
      []
    end
    
    def ca_bundle_path
      if use_system_ssl_cert_chain? && File.exist?(OpenSSL::X509::DEFAULT_CERT_FILE)
        OpenSSL::X509::DEFAULT_CERT_FILE
      else
        local_cert_path # ca-bundle.crt built from source, see resources/README.md
      end
    end

    def local_cert_path
      File.expand_path(File.join("..", "..", "..", "resources", "ca-bundle.crt"), __FILE__)
    end

  private
    def default_port
      if secure?
        443
      else
        80
      end
    end

  end

end
