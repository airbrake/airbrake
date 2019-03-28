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
  # Rack is a namespace for all Rack-related features.
  module Rack
    # Adds the list of default Rack filters that read Rack request information
    # and append it to notices.
    # @since 9.0.0
    def self.add_default_filters
      [
        Airbrake::Rack::ContextFilter,
        Airbrake::Rack::UserFilter,
        Airbrake::Rack::SessionFilter,
        Airbrake::Rack::HttpParamsFilter,
        Airbrake::Rack::HttpHeadersFilter,
        Airbrake::Rack::RouteFilter
      ].each do |filter|
        Airbrake.add_filter(filter.new)
      end
    end
  end
end
