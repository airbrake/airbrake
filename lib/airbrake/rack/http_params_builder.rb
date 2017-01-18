module Airbrake
  module Rack
    ##
    # Adds HTTP request parameters.
    #
    # @since v5.7.0
    class HttpParamsBuilder
      def call(notice, request)
        notice[:params] = request.params

        rails_params = request.env['action_dispatch.request.parameters']
        notice[:params].merge!(rails_params) if rails_params
      end
    end
  end
end
