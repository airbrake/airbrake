# frozen_string_literal: true

require 'airbrake/rails/event'

module Airbrake
  module Rails
    # ActionControllerNotifySubscriber sends route stat information, including
    # performance data.
    #
    # @since v8.0.0
    class ActionControllerNotifySubscriber
      def initialize(rails_vsn)
        @rails_7_or_above = rails_vsn.to_i >= 7
      end

      def call(*args)
        return unless Airbrake::Config.instance.performance_stats

        routes = Airbrake::Rack::RequestStore[:routes]
        return if !routes || routes.none?

        event = Airbrake::Rails::Event.new(*args)

        routes.each do |route, _params|
          Airbrake.notify_request(
            method: event.method,
            route: route,
            status_code: event.status_code,
            timing: event.duration,

            # On Rails 7+ `ActiveSupport::Notifications::Event#time` returns an
            # instance of Float. It represents monotonic time in milliseconds.
            # Airbrake Ruby expects that the provided time is in seconds. Hence,
            # we need to convert it from milliseconds to seconds. In the
            # versions below Rails 7, time is an instance of Time.
            #
            # Relevant commit:
            # https://github.com/rails/rails/commit/81d0dc90becfe0b8e7f7f26beb66c25d84b8ec7f
            time: @rails_7_or_above ? event.time / 1000 : event.time,
          )
        end
      end
    end
  end
end
