require 'net/http'

# Monkey-patch Net::HTTP to benchmark it.
Net::HTTP.class_eval do
  alias_method :request_without_airbrake, :request

  def request(request, *args, &block)
    routes = Airbrake::Rack::RequestStore[:routes]
    if !routes || routes.none?
      response = request_without_airbrake(request, *args, &block)
    else
      elapsed = Airbrake::Benchmark.measure do
        response = request_without_airbrake(request, *args, &block)
      end

      routes.each do |route_path, _params|
        Airbrake::Rack::RequestStore[:routes][route_path][:groups][:http] = elapsed
      end
    end

    response
  end
end
