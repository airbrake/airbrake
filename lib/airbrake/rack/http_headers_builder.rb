module Airbrake
  module Rack
    ##
    # Adds HTTP request parameters.
    #
    # @since v5.7.0
    class HttpHeadersBuilder
      ##
      # @return [Array<String>] the prefixes of the majority of HTTP headers in
      #   Rack (some prefixes match the header names for simplicity)
      HTTP_HEADER_PREFIXES = [
        'HTTP_'.freeze,
        'CONTENT_TYPE'.freeze,
        'CONTENT_LENGTH'.freeze
      ].freeze

      def call(notice, request)
        http_headers = request.env.map.with_object({}) do |(key, value), headers|
          if HTTP_HEADER_PREFIXES.any? { |prefix| key.to_s.start_with?(prefix) }
            headers[key] = value
          end

          headers
        end

        notice[:environment].merge!(
          httpMethod: request.request_method,
          referer: request.referer,
          headers: http_headers
        )

        notice[:environment]
      end
    end
  end
end
