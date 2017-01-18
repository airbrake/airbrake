module Airbrake
  module Rack
    ##
    # Adds HTTP session.
    #
    # @since v5.7.0
    class SessionBuilder
      def call(notice, request)
        session = request.session
        notice[:session] = session if session
      end
    end
  end
end
