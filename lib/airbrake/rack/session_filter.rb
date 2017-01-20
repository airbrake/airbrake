module Airbrake
  module Rack
    ##
    # Adds HTTP session.
    #
    # @since v5.7.0
    class SessionFilter
      ##
      # @see {Airbrake::FilterChain#refine}
      def call(notice)
        return unless (request = notice.stash[:rack_request])

        session = request.session
        notice[:session] = session if session
      end
    end
  end
end
