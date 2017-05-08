module Resque
  module Failure
    ##
    # Provides Resque integration with Airbrake.
    #
    # @since v5.0.0
    # @see https://github.com/resque/resque/wiki/Failure-Backends
    class Airbrake < Base
      def save
        ::Airbrake.notify_sync(exception, payload) do |notice|
          notice[:context][:component] = 'resque'
          notice[:context][:action] = payload['class'].to_s
        end
      end
    end
  end
end
