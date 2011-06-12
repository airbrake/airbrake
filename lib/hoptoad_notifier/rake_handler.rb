# Patch Rake::Application to handle errors with Hoptoad
# Code taken from Rake source
module HoptoadNotifier::RakeHandler
  def standard_exception_handling
    begin
      yield
    rescue SystemExit => ex
      # Exit silently with current status
      raise
    rescue OptionParser::InvalidOption => ex
      # Exit silently
      exit(false)
    rescue Exception => ex
      if tty_output?
        handle_exception_without_hoptoad(ex)
      else
        HoptoadNotifier.notify(ex, :component => reconstruct_command_line, :cgi_data => ENV)
      end
      exit(false)
    end
  end
        
  def handle_exception_without_hoptoad(ex)
    # Exit with error message
    $stderr.puts "#{name} aborted!"
    $stderr.puts ex.message
    if options.trace
      $stderr.puts ex.backtrace.join("\n")
    else
      $stderr.puts ex.backtrace.find {|str| str =~ /#{@rakefile}/ } || ""
      $stderr.puts "(See full trace by running task with --trace)"
    end
  end
  
  def reconstruct_command_line
    "rake #{ARGV.join( ' ' )}"
  end
end

Rake.application.instance_eval do
  class << self
    include HoptoadNotifier::RakeHandler
  end
end

