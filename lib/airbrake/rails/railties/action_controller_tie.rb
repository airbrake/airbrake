# frozen_string_literal: true

require 'airbrake/rails/action_controller'
require 'airbrake/rails/action_controller_route_subscriber'
require 'airbrake/rails/action_controller_notify_subscriber'
require 'airbrake/rails/action_controller_performance_breakdown_subscriber'

module Airbrake
  module Rails
    module Railties
      # Ties Airbrake APM (routes) and HTTP clients with Rails.
      #
      # @api private
      # @since v13.0.1
      class ActionControllerTie
        def initialize
          @route_subscriber = Airbrake::Rails::ActionControllerRouteSubscriber.new
          @notify_subscriber = Airbrake::Rails::ActionControllerNotifySubscriber.new
          @performance_breakdown_subscriber =
            Airbrake::Rails::ActionControllerPerformanceBreakdownSubscriber.new
        end

        def call
          ActiveSupport.on_load(:action_controller, run_once: true, yield: self) do
            # Patches ActionController with methods that allow us to retrieve
            # interesting request data. Appends that information to notices.
            ::ActionController::Base.include(Airbrake::Rails::ActionController)

            tie_routes_apm
            tie_http_integrations
          end
        end

        private

        def tie_routes_apm
          [
            # Cache route information for the duration of the request.
            ['start_processing.action_controller', @route_subscriber],

            # Send route stats.
            ['process_action.action_controller', @notify_subscriber],

            # Send performance breakdown: where a request spends its time.
            ['process_action.action_controller', @performance_breakdown_subscriber],
          ].each do |(event, callback)|
            ActiveSupport::Notifications.subscribe(event, callback)
          end
        end

        def tie_http_integrations
          tie_net_http
          tie_curl
          tie_http
          tie_http_client
          tie_typhoeus
          tie_excon
        end

        def tie_net_http
          require 'airbrake/rails/net_http' if defined?(Net) && defined?(Net::HTTP)
        end

        def tie_curl
          require 'airbrake/rails/curb' if defined?(Curl) && defined?(Curl::CURB_VERSION)
        end

        def tie_http
          require 'airbrake/rails/http' if defined?(HTTP) && defined?(HTTP::Client)
        end

        def tie_http_client
          require 'airbrake/rails/http_client' if defined?(HTTPClient)
        end

        def tie_typhoeus
          require 'airbrake/rails/typhoeus' if defined?(Typhoeus)
        end

        def tie_excon
          return unless defined?(Excon)

          require 'airbrake/rails/excon_subscriber'
          ActiveSupport::Notifications.subscribe(/excon/, Airbrake::Rails::Excon.new)
          ::Excon.defaults[:instrumentor] = ActiveSupport::Notifications
        end
      end
    end
  end
end
