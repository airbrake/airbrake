module Typhoeus
  # Monkey-patch to measure request timing.
  class Request
    alias run_without_airbrake run

    def run
      Airbrake::Rack.capture_http_performance do
        run_without_airbrake
      end
    end
  end
end
