module HoptoadNotifier
  class Notice

    # The exception that caused this notice, if any
    attr_reader :exception

    # The API key for the project to which this notice should be sent
    attr_reader :api_key

    # The backtrace from the given exception or hash.
    attr_reader :backtrace

    # The name of the class of error (such as RuntimeError)
    attr_reader :error_class

    # The server environment and request environment merged together.
    attr_reader :environment

    # The message from the exception, or a general description of the error
    attr_reader :error_message

    # See Configuration#backtrace_filters
    attr_reader :backtrace_filters

    # See Configuration#params_filters
    attr_reader :params_filters

    # See Configuration#environment_filters
    attr_reader :environment_filters

    # A hash of parameters from the query string or post body.
    attr_reader :parameters
    alias_method :params, :parameters

    # A hash of session data from the request
    attr_reader :session_data

    # The path to the project that caused the error (usually RAILS_ROOT)
    attr_reader :project_root

    # The URL at which the error occurred (if any)
    attr_reader :url

    # See Configuration#ignore
    attr_reader :ignore

    # See Configuration#ignore_by_filters
    attr_reader :ignore_by_filters

    def initialize(args)
      self.args         = args
      self.exception    = args[:exception]
      self.api_key      = args[:api_key]
      self.project_root = args[:project_root]
      self.url          = args[:url]

      self.ignore              = args[:ignore]              || []
      self.ignore_by_filters   = args[:ignore_by_filters]   || []
      self.backtrace_filters   = args[:backtrace_filters]   || []
      self.params_filters      = args[:params_filters]      || []
      self.environment_filters = args[:environment_filters] || []
      self.parameters          = args[:parameters]          || {}

      self.environment   = args[:environment] || ENV.to_hash
      self.backtrace     = exception_attribute(:backtrace, caller)
      self.error_class   = exception_attribute(:error_class) {|exception| exception.class.name }
      self.error_message = exception_attribute(:error_message, 'Notification') do |exception|
        "#{exception.class.name}: #{exception.message}"
      end

      find_session_data
      clean_backtrace
      clean_params
      clean_environment
    end

    def to_yaml
      data = { 'api_key'       => api_key,
               'error_class'   => error_class,
               'error_message' => "#{error_class}: #{error_message}",
               'backtrace'     => backtrace,
               'environment'   => environment,
               'request'       => {
                 'params'     => parameters,
                 'rails_root' => project_root,
                 'url'        => url
               },
               'session'       => { 'data' => session_data } }
      YAML.dump 'notice' => data
    end

    def ignore?
      ignored_class_names.include?(error_class) ||
        ignore_by_filters.any? {|filter| filter.call(self) }
    end

    # Allows properties to be accessed using a hash-like syntax, such as:
    #   notice[:error_message]
    def [](method)
      case method
      when :request
        self
      else
        send(method)
      end
    end

    private

    attr_writer :exception, :api_key, :backtrace, :error_class, :error_message,
      :environment, :backtrace_filters, :parameters, :params_filters,
      :environment_filters, :session_data, :project_root, :url, :ignore,
      :ignore_by_filters

    # Arguments given in the initializer
    attr_accessor :args

    # Runs backtrace filters on the backtrace, and converts massive,
    # multiline traces into arrays.
    def clean_backtrace
      if backtrace.to_a.size == 1
        self.backtrace = backtrace.to_a.first.split(/\n\s*/)
      end

      filtered = backtrace.to_a.map do |line|
        backtrace_filters.inject(line) do |line, proc|
          proc.call(line)
        end
      end

      self.backtrace = filtered.compact
    end

    # Gets a property named +attribute+ of an exception, either from an actual
    # exception or a hash.
    #
    # If an exception is available, #from_exception will be used. Otherwise,
    # a key named +attribute+ will be used from the #args.
    #
    # If no exception or hash key is available, +default+ will be used.
    def exception_attribute(attribute, default = nil, &block)
      if exception
        from_exception(attribute, &block)
      else
        args[attribute] || default
      end
    end

    # Gets a property named +attribute+ from an exception.
    #
    # If a block is given, it will be used when getting the property from an
    # exception. The block should accept and exception and return the value for
    # the property.
    #
    # If no block is given, a method with the same name as +attribute+ will be
    # invoked for the value.
    def from_exception(attribute)
      if block_given?
        yield(exception)
      else
        exception.send(attribute)
      end
    end

    # Removes non-serializable data from the given attribute.
    # See #clean_unserializable_data
    def clean_unserializable_data_from(attribute)
      self.send(:"#{attribute}=", clean_unserializable_data(send(attribute)))
    end

    # Removes non-serializable data. Allowed data types are strings, arrays,
    # and hashes. All other types are converted to strings.
    # TODO: move this onto Hash
    def clean_unserializable_data(data)
      if data.respond_to?(:to_hash)
        data.inject({}) do |result, (key, value)|
          result.merge(key => clean_unserializable_data(value))
        end
      elsif data.respond_to?(:to_ary)
        data.collect do |value|
          clean_unserializable_data(value)
        end
      else
        data.to_s
      end
    end

    # Replaces the contents of params that match params_filters.
    # TODO: extract this to a different class
    def clean_params
      clean_unserializable_data_from(:parameters)
      if params_filters
        parameters.keys.each do |key|
          parameters[key] = "[FILTERED]" if params_filters.any? do |filter|
            key.to_s.include?(filter)
          end
        end
      end
    end

    # Replaces the contents of params that match params_filters.
    # TODO: extract this to a different class
    def clean_environment
      clean_unserializable_data_from(:environment)
      if environment_filters
        environment.keys.each do |key|
          environment[key] = "[FILTERED]" if environment_filters.any? do |filter|
            key.to_s.include?(filter)
          end
        end
      end
    end

    def find_session_data
      self.session_data = args[:session_data] || args[:session] || {}
      self.session_data = session_data[:data] if session_data[:data]
    end

    # Converts the mixed class instances and class names into just names
    # TODO: move this into Configuration or another class
    def ignored_class_names
      ignore.collect do |string_or_class|
        if string_or_class.respond_to?(:name)
          string_or_class.name
        else
          string_or_class
        end
      end
    end

  end
end
