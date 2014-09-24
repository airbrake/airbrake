module Airbrake
  class ExceptionWrapper
    def initialize ex, backtrace_filters, opts = {}
      @ex = ex
      @opts = opts
      @backtrace_filters = backtrace_filters
    end

    def error_class
      @opts[:error_class] || (@ex && @ex.class.name)
    end

    def error_message
      out = ''
      if error_class
        out << error_class << ': '
      end
      if @opts[:error_message]
        out << @opts[:error_message]
      elsif @ex && @ex.message
        out << @ex.message
      else
        out << 'Notification'
      end
    end

    def backtrace
      bt = (@ex && @ex.backtrace) || @opts[:backtrace] || caller
      Backtrace.parse bt, :filters => @backtrace_filters
    end

    def to_hash
      {
        :type       =>  error_class,
        :message    =>  error_message,
        :backtrace  =>  backtrace.lines.map do |line| 
          {
            :file     =>  line.file, 
            :line     =>  line.number.to_i, 
            :function =>  line.method_name
          }
        end
      }
    end
  end
end