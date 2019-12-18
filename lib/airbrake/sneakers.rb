module Airbrake
  module Sneakers
    # Provides integration with Sneakers.
    #
    # @see https://github.com/jondot/sneakers
    # @since v7.2.0
    class ErrorReporter
      # @return [Array<Symbol>] ignored keys values of which raise
      #   SystemStackError when `as_json` is called on them
      # @see https://github.com/airbrake/airbrake/issues/850
      IGNORED_KEYS = %i[delivery_tag consumer channel].freeze

      def call(exception, worker = nil, **context)
        Airbrake.notify(exception, filter_context(context)) do |notice|
          notice[:context][:component] = 'sneakers'
          notice[:context][:action] = worker.class.to_s
        end
      end

      private

      def filter_context(context)
        return context unless context[:delivery_info]
        h = context.dup
        h[:delivery_info] = context[:delivery_info].reject do |k, _v|
          IGNORED_KEYS.include?(k)
        end
        h
      end
    end
  end
end

Sneakers.error_reporters << Airbrake::Sneakers::ErrorReporter.new

module Sneakers
  # @todo Migrate to Sneakers v2.12.0 middleware API when it's released
  # @see https://github.com/jondot/sneakers/pull/364
  module Worker
    DEFAULT_SPAN = 'other'.freeze

    # Sneakers v2.7.0+ renamed `do_work` to `process_work`.
    if method_defined?(:process_work)
      alias process_work_without_airbrake process_work
    else
      alias process_work_without_airbrake do_work
    end

    def process_work(delivery_info, metadata, msg, handler)
      timed_trace = Airbrake::TimedTrace.span(DEFAULT_SPAN) do
        process_work_without_airbrake(delivery_info, metadata, msg, handler)
      end
    rescue Exception => exception # rubocop:disable Lint/RescueException
      Airbrake.notify_queue(queue: self.class.to_s, error_count: 1)
      raise exception
    else
      Airbrake.notify_queue(
        queue: self.class.to_s,
        error_count: 0,
        groups: timed_trace.spans,
      )
    end
  end
end
