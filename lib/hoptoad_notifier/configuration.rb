module HoptoadNotifier
  class Configuration

    OPTIONS = [:api_key, :host, :port, :secure, :http_open_timeout, :http_read_timeout,
      :proxy_host, :proxy_port, :proxy_user, :proxy_pass, :params_filters,
      :environment_filters, :backtrace_filters, :ignore_by_filters, :ignore,
      :ignore_user_agent, :port, :protocol, :development_environments].freeze

    # The API key for your project, found on the project edit form.
    attr_accessor :api_key

    # The host to connect to (defaults to hoptoadapp.com).
    attr_accessor :host

    # The port on which your Hoptoad server runs (defaults to 443 for secure
    # connections, 80 for insecure connections).
    attr_accessor :port

    # +true+ for https connections, +false+ for http connections.
    attr_accessor :secure

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

    # A list of parameters that should be filtered out of what is sent to Hoptoad.
    # By default, all "password" attributes will have their contents replaced.
    attr_reader :params_filters

    # A list of environment keys that should be filtered out of what is send to Hoptoad.
    # Empty by default.
    attr_reader :environment_filters

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

    DEFAULT_PARAMS_FILTERS = %w(password password_confirmation).freeze

    DEFAULT_BACKTRACE_FILTERS = [
      lambda { |line|
        if defined?(RAILS_ROOT)
          line.gsub(/#{RAILS_ROOT}/, "[RAILS_ROOT]")
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
      lambda { |line| line if line !~ %r{lib/hoptoad_notifier} }
    ].freeze

    IGNORE_DEFAULT = ['ActiveRecord::RecordNotFound',
                      'ActionController::RoutingError',
                      'ActionController::InvalidAuthenticityToken',
                      'CGI::Session::CookieStore::TamperedWithCookie',
                      'ActionController::UnknownAction']

    # Some of these don't exist for Rails 1.2.*, so we have to consider that.
    IGNORE_DEFAULT.map!{|e| eval(e) rescue nil }.compact!
    IGNORE_DEFAULT.freeze

    alias_method :secure?, :secure

    def initialize
      @secure                   = false
      @host                     = 'hoptoadapp.com'
      @http_open_timeout        = 2
      @http_read_timeout        = 5
      @params_filters           = DEFAULT_PARAMS_FILTERS.dup
      @environment_filters      = []
      @backtrace_filters        = DEFAULT_BACKTRACE_FILTERS.dup
      @ignore_by_filters        = []
      @ignore                   = IGNORE_DEFAULT.dup
      @ignore_user_agent        = []
      @development_environments = %w(development test)
    end

    # Takes a block and adds it to the list of backtrace filters. When the filters
    # run, the block will be handed each line of the backtrace and can modify
    # it as necessary. For example, by default a path matching the RAILS_ROOT
    # constant will be transformed into "[RAILS_ROOT]"
    def filter_backtrace(&block)
      self.backtrace_filters << block
    end

    # Takes a block and adds it to the list of ignore filters.  When the filters
    # run, the block will be handed the exception.  If the block yields a value
    # equivalent to "true," the exception will be ignored, otherwise it will be
    # processed by hoptoad.
    def ignore_by_filter(&block)
      self.ignore_by_filters << block
    end

    # Sets the list of ignored errors to only what is passed in here. This method
    # can be passed a single error or a list of errors.
    def ignore_only=(names)
      @ignore = [names].flatten
    end

    # Sets the list of ignored user agents to only what is passed in here. This method
    # can be passed a single user agent or a list of user agents.
    def ignore_user_agent_only=(names)
      @ignore_user_agent = [names].flatten
    end

    # Allows config options to be read like a hash
    def [](option)
      send(option)
    end

    # Returns a hash of all configurable options
    def to_hash
      OPTIONS.inject({}) do |hash, option|
        hash.merge(option.to_sym => send(option))
      end
    end

    # Returns a hash of all configurable options merged with +hash+
    def merge(hash)
      to_hash.merge(hash)
    end

    def port #:nodoc:
      @port ||= if secure?
                  443
                else
                  80
                end
    end

    def protocol #:nodoc:
      if secure?
        'https'
      else
        'http'
      end
    end

    # Returns false if in a development environment, false otherwise.
    def public?
      !development_environments.include?(environment_name)
    end

    private

    def environment_name
      RAILS_ENV if defined?(RAILS_ENV)
    end
  end
end
