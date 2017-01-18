module Airbrake
  module Rack
    ##
    # A builder that appends Rack request body to the notice.
    #
    # @example
    #   # Read and append up to 512 bytes from Rack request's body.
    #   Airbrake.add_rack_builder(Airbrake::Rack::RequestBodyBuilder.new(512))
    #
    # @since v5.7.0
    # @note This builder is *not* included by default.
    class RequestBodyBuilder
      ##
      # @param [Integer] length The maximum number of bytes to read
      def initialize(length = 4096)
        @length = length
      end

      ##
      # @see Airbrake.add_rack_builder
      def call(notice, request)
        return unless request.body

        notice[:environment][:body] = request.body.read(@length)
        request.body.rewind
      end
    end
  end
end
