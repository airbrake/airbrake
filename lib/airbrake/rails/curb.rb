# frozen_string_literal: true

module Curl
  # Monkey-patch to measure request timing.
  class Easy
    alias http_without_airbrake http

    def http(verb)
      Airbrake::Rack.capture_timing(:http) do
        http_without_airbrake(verb)
      end
    end

    alias perform_without_airbrake perform

    def perform(&block)
      Airbrake::Rack.capture_timing(:http) do
        perform_without_airbrake(&block)
      end
    end
  end
end

module Curl
  # Monkey-patch to measure request timing.
  class Multi
    class << self
      alias http_without_airbrake http

      def http(urls_with_config, multi_options = {}, &block)
        Airbrake::Rack.capture_timing(:http) do
          http_without_airbrake(urls_with_config, multi_options, &block)
        end
      end
    end
  end
end
