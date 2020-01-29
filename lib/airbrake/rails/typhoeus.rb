# frozen_string_literal: true

module Typhoeus
  # Monkey-patch to measure request timing.
  class Request
    alias run_without_airbrake run

    def run
      Airbrake::Rack.capture_timing(:http) do
        run_without_airbrake
      end
    end
  end
end
