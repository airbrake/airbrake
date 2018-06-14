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
