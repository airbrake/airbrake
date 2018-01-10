module Airbrake
  module Sneakers
    ##
    # Provides integration with Sneakers.
    #
    # @see https://github.com/jondot/sneakers
    # @since v7.2.0
    class ErrorReporter
      def call(exception, worker = nil, **context)
        Airbrake.notify(exception, context) do |notice|
          notice[:context][:component] = 'sneakers'
          notice[:context][:action] = worker.class.to_s
        end
      end
    end
  end
end

Sneakers.error_reporters << Airbrake::Sneakers::ErrorReporter.new
