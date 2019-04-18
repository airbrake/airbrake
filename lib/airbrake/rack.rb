require 'airbrake/rack/user'
require 'airbrake/rack/user_filter'
require 'airbrake/rack/context_filter'
require 'airbrake/rack/session_filter'
require 'airbrake/rack/http_params_filter'
require 'airbrake/rack/http_headers_filter'
require 'airbrake/rack/request_body_filter'
require 'airbrake/rack/route_filter'
require 'airbrake/rack/middleware'
require 'airbrake/rack/request_store'

module Airbrake
  # Rack is a namespace for all Rack-related code.
  module Rack
    # @api private
    # @since 9.2.0
    def self.capture_http_performance
      routes = Airbrake::Rack::RequestStore[:routes]
      if !routes || routes.none?
        response = yield
      else
        elapsed = Airbrake::Benchmark.measure do
          response = yield
        end

        routes.each do |_route_path, params|
          params[:groups][:http] = elapsed
        end
      end

      response
    end
  end
end
