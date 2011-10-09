# Patch Rake::Application to handle errors with Airbrake
module Airbrake::RakeHandler
  def self.included(klass)
    klass.class_eval do
      include Rake087Methods unless defined?(Rake::VERSION) && Rake::VERSION >= '0.9.0'
      alias_method :display_error_message_without_airbrake, :display_error_message
      alias_method :display_error_message, :display_error_message_with_airbrake
    end
  end

  def display_error_message_with_airbrake(ex)
    if Airbrake.sender && Airbrake.configuration &&
        (Airbrake.configuration.rescue_rake_exceptions || 
          (Airbrake.configuration.rescue_rake_exceptions===nil && !self.tty_output?))

      Airbrake.notify(ex, :component => reconstruct_command_line, :cgi_data => ENV)
    end

    display_error_message_without_airbrake(ex)
  end

  def reconstruct_command_line
    "rake #{ARGV.join( ' ' )}"
  end
  
  # This module brings Rake 0.8.7 error handling to 0.9.0 standards
  module Rake087Methods
    # Method taken from Rake 0.9.0 source
    # 
    # Provide standard exception handling for the given block.
    def standard_exception_handling
      begin
        yield
      rescue SystemExit => ex
        # Exit silently with current status
        raise
      rescue OptionParser::InvalidOption => ex
        $stderr.puts ex.message
        exit(false)
      rescue Exception => ex
        # Exit with error message
        display_error_message(ex)
        exit(false)
      end
    end

    # Method extracted from Rake 0.8.7 source
    def display_error_message(ex)
      $stderr.puts "#{name} aborted!"
      $stderr.puts ex.message
      if options.trace
        $stderr.puts ex.backtrace.join("\n")
      else
        $stderr.puts ex.backtrace.find {|str| str =~ /#{@rakefile}/ } || ""
        $stderr.puts "(See full trace by running task with --trace)"
      end
    end
  end
end

Rake.application.instance_eval do
  class << self
    include Airbrake::RakeHandler
  end
end

