# frozen_string_literal: true

# Monkey-patch Net::HTTP to benchmark it.
Net::HTTP.class_eval do
  alias_method :request_without_airbrake, :request

  def request(request, *args, &block)
    Airbrake::Rack.capture_timing(:http) do
      request_without_airbrake(request, *args, &block)
    end
  end
end
