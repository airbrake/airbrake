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
  alias initialize_without_airbrake initialize

  ##
  # @see https://goo.gl/MvlYq3 Logger#initialize
  def initialize(*args)
    @airbrake_notifier = Airbrake[:default]
    @airbrake_severity_level = WARN
    initialize_without_airbrake(*args)
  end

  ##
  # @return [Airbrake::Notifier] notifier to be used to send notices
  attr_accessor :airbrake_notifier

  ##
  # @example
  #   logger.airbrake_severity_level = Logger::FATAL
  # @return [Integer]
  attr_accessor :airbrake_severity_level

  ##
  # @see https://goo.gl/8zPyoM Logger#add
  def add(severity, message = nil, progname = nil, &block)
    if severity >= airbrake_severity_level && airbrake_notifier
      notify_airbrake(severity, message || progname)
    end
    add_without_airbrake(severity, message, progname, &block)
  end

  private

  def notify_airbrake(severity, message)
    notice = airbrake_notifier.build_notice(message)

    # Get rid of unwanted internal Logger frames. Examples:
    # * /ruby-2.4.0/lib/ruby/2.4.0/logger.rb
    # * /gems/activesupport-4.2.7.1/lib/active_support/logger.rb
    backtrace = notice[:errors].first[:backtrace]
    notice[:errors].first[:backtrace] =
      backtrace.drop_while { |frame| frame[:file] =~ %r{/logger.rb\z} }

    notice[:context][:component] = 'log'
    notice[:context][:severity] = airbrake_severity(severity)

    airbrake_notifier.notify(notice)
  end

  def airbrake_severity(severity)
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
end
