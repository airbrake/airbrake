# frozen_string_literal: true

require 'airbrake/rails/active_record'
require 'airbrake/rails/active_record_subscriber'

module Airbrake
  module Rails
    module Railties
      # Ties Airbrake APM (queries) with Rails.
      #
      # @api private
      # @since v13.0.1
      class ActiveRecordTie
        def initialize
          @active_record_subscriber = Airbrake::Rails::ActiveRecordSubscriber.new
        end

        def call
          ActiveSupport.on_load(:active_record, run_once: true, yield: self) do
            tie_activerecord_callback_fix
            tie_activerecord_apm
          end
        end

        private

        def tie_activerecord_callback_fix
          # Reports exceptions occurring in some bugged ActiveRecord callbacks.
          # Applicable only to the versions of Rails lower than 4.2.
          return unless defined?(::Rails)
          return if Gem::Version.new(::Rails.version) > Gem::Version.new('4.2')

          ActiveRecord::Base.include(Airbrake::Rails::ActiveRecord)
        end

        def tie_activerecord_apm
          # Some Rails apps don't use ActiveRecord.
          return unless defined?(::ActiveRecord)

          # However, some dependencies might still require it, so we need an
          # extra check. Apps that don't need ActiveRecord will likely have no
          # AR configurations defined. We will skip APM integration in that
          # case. See: https://github.com/airbrake/airbrake/issues/1222
          configurations = ::ActiveRecord::Base.configurations
          return unless configurations.any?

          # Send SQL queries.
          ActiveSupport::Notifications.subscribe(
            'sql.active_record',
            @active_record_subscriber,
          )

          # Filter out parameters from SQL body.
          sql_filter = Airbrake::Filters::SqlFilter.new(
            detect_activerecord_adapter(configurations),
          )
          Airbrake.add_performance_filter(sql_filter)
        end

        # Rails 6+ introduces the `configs_for` API instead of the deprecated
        # `#[]`, so we need an updated call.
        def detect_activerecord_adapter(configurations)
          unless configurations.respond_to?(:configs_for)
            return configurations[::Rails.env]['adapter']
          end

          cfg = configurations.configs_for(env_name: ::Rails.env).first
          # Rails 7+ API : Rails 6 API.
          cfg.respond_to?(:adapter) ? cfg.adapter : cfg.config['adapter']
        end
      end
    end
  end
end
