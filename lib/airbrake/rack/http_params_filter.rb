module Airbrake
  module Rack
    ##
    # Adds HTTP request parameters.
    #
    # @since v5.7.0
    class HttpParamsFilter
      ##
      # @see {Airbrake::FilterChain#refine}
      def call(notice)
        return unless (request = notice.stash[:rack_request])

        notice[:params] = request.params

        rails_params = request.env['action_dispatch.request.parameters']
        notice[:params].merge!(rails_params) if rails_params
      end
    end
  end
end
