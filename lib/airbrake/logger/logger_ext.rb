##
# Redefine +Logger+ from stdlib, so it can both log and report errors to
# Airbrake.
#
# @example
#   # Create a logger like you normally do.
#   logger = Logger.new(STDOUT)
#
#   # Assign a default Airbrake notifier
#   logger.airbrake_notifier = Airbrake[:default]
#
#   # Just use the logger like you normally do.
#   logger.fatal('oops')
class Logger
  # Store the orginal methods to use them later.
  alias add_without_airbrake add

  ##
  # @return [Airbrake::Notifier] notifier to be used to send notices
  attr_accessor :airbrake_notifier

  ##
  # @return [Integer]
  attr_reader :airbrake_severity_level

  ##
  # Sets airbrake severity level. Does not permit values below `Logger::WARN`.
  #
  # @example
  #   logger.airbrake_severity_level = Logger::FATAL
  # @return [void]
  def airbrake_severity_level=(level)
    level = WARN if level < WARN
    @airbrake_severity_level = level
  end

  ##
  # @see https://goo.gl/8zPyoM Logger#add
  def add(severity, message = nil, progname = nil, &block)
    if severity >= current_airbrake_severity && current_airbrake_notifier
      notify_airbrake(severity, message || progname)
    end
    add_without_airbrake(severity, message, progname, &block)
  end

  private

  def notify_airbrake(severity, message)
    notice = current_airbrake_notifier.build_notice(message)

    # Get rid of unwanted internal Logger frames. Examples:
    # * /ruby-2.4.0/lib/ruby/2.4.0/logger.rb
    # * /gems/activesupport-4.2.7.1/lib/active_support/logger.rb
    backtrace = notice[:errors].first[:backtrace]
    notice[:errors].first[:backtrace] =
      backtrace.drop_while { |frame| frame[:file] =~ %r{/logger.rb\z} }

    notice[:context][:component] = 'log'
    notice[:context][:severity] = normalize_airbrake_severity(severity)

    current_airbrake_notifier.notify(notice)
  end

  def normalize_airbrake_severity(severity)
    (case severity
     when DEBUG
       'debug'
     when INFO
       'info'
     when WARN
       'warning'
     when ERROR, UNKNOWN
       'error'
     when FATAL
       'critical'
     end).freeze
  end

  # @!macro helper_method
  #   @note We define this helper instead of using instance variable to avoid
  #     Ruby's warnings about uninitialized ivars.

  ##
  # @macro helper_method
  def current_airbrake_notifier
    airbrake_notifier || Airbrake[:default]
  end

  ##
  # @marcro helper_method
  def current_airbrake_severity
    airbrake_severity_level || WARN
  end
end
