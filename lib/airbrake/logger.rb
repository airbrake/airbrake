require 'logger'
require 'delegate'

module Airbrake
  # Decorator for +Logger+ from stdlib. Endows loggers the ability to both log
  # and report errors to Airbrake.
  #
  # @example
  #   # Create a logger like you normally do and decorate it.
  #   logger = Airbrake::AirbrakeLogger.new(Logger.new(STDOUT))
  #
  #   # Just use the logger like you normally do.
  #   logger.fatal('oops')
  class AirbrakeLogger < SimpleDelegator
    # @example
    #   # Assign a default Airbrake notifier
    #   logger.airbrake_notifier = Airbrake[:default]
    # @return [Airbrake::Notifier] notifier to be used to send notices
    attr_accessor :airbrake_notifier

    # @return [Integer]
    attr_reader :airbrake_level

    def initialize(logger)
      __setobj__(logger)
      @airbrake_notifier = Airbrake[:default]
      @airbrake_level = Logger::WARN
    end

    # @see Logger#warn
    def warn(progname = nil, &block)
      notify_airbrake(Logger::WARN, progname)
      super
    end

    # @see Logger#error
    def error(progname = nil, &block)
      notify_airbrake(Logger::ERROR, progname)
      super
    end

    # @see Logger#fatal
    def fatal(progname = nil, &block)
      notify_airbrake(Logger::FATAL, progname)
      super
    end

    # @see Logger#unknown
    def unknown(progname = nil, &block)
      notify_airbrake(Logger::UNKNOWN, progname)
      super
    end

    # Sets airbrake severity level. Does not permit values below `Logger::WARN`.
    #
    # @example
    #   logger.airbrake_level = Logger::FATAL
    # @return [void]
    def airbrake_level=(level)
      if level < Logger::WARN
        raise "Airbrake severity level #{level} is not allowed. " \
              "Minimum allowed level is #{Logger::WARN}"
      end
      @airbrake_level = level
    end

    private

    def notify_airbrake(severity, progname)
      return if severity < @airbrake_level || !@airbrake_notifier

      @airbrake_notifier.notify(progname) do |notice|
        # Get rid of unwanted internal Logger frames. Examples:
        # * /ruby-2.4.0/lib/ruby/2.4.0/logger.rb
        # * /gems/activesupport-4.2.7.1/lib/active_support/logger.rb
        backtrace = notice[:errors].first[:backtrace]
        notice[:errors].first[:backtrace] =
          backtrace.drop_while { |frame| frame[:file] =~ %r{/logger.rb\z} }

        notice[:context][:component] = 'log'
        notice[:context][:severity] = normalize_severity(severity)
      end
    end

    def normalize_severity(severity)
      (case severity
       when Logger::WARN then 'warning'
       when Logger::ERROR, Logger::UNKNOWN then 'error'
       when Logger::FATAL then 'critical'
       else
         raise "Unknown airbrake severity: #{severity}"
       end).freeze
    end
  end
end
