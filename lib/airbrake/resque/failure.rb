module Resque
  module Failure
    ##
    # Provides Resque integration with Airbrake.
    #
    # @since v5.0.0
    # @see https://github.com/resque/resque/wiki/Failure-Backends
    class Airbrake < Base
      def save
        return unless (notice = ::Airbrake.build_notice(exception, payload))
        notice[:context][:component] = 'resque'
        notice[:context][:action] = payload['class'].to_s

        ::Airbrake.notify_sync(notice)
      end
    end
  end
end
