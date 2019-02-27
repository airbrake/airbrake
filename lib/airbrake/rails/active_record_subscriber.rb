module Airbrake
  module Rails
    # ActiveRecordSubscriber sends SQL information, including performance data.
    #
    # @since v8.1.0
    class ActiveRecordSubscriber
      def call(*args)
        routes = Airbrake::Rack::RequestStore[:routes]
        return if !routes || routes.none?

        event = ActiveSupport::Notifications::Event.new(*args)
        frame = last_caller

        routes.each do |route, method|
          Airbrake.notify_query(
            route: route,
            method: method,
            query: event.payload[:sql],
            func: frame[:function],
            file: frame[:file],
            line: frame[:line],
            start_time: event.time,
            end_time: event.end
          )
        end
      end

      private

      def last_caller
        exception = StandardError.new.tap do |ex|
          ex.set_backtrace(::Rails.backtrace_cleaner.clean(Kernel.caller).first(1))
        end
        Airbrake::Backtrace.parse(exception).first
      end
    end
  end
end

Airbrake.add_performance_filter(
  Airbrake::Filters::SqlFilter.new(
    ActiveRecord::Base.connection_config[:adapter]
  )
)

ActiveSupport::Notifications.subscribe(
  'sql.active_record', Airbrake::Rails::ActiveRecordSubscriber.new
)
