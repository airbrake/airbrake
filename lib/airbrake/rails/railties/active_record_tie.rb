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
          return unless defined?(ActiveRecord)

          # Send SQL queries.
          ActiveSupport::Notifications.subscribe(
            'sql.active_record',
            @active_record_subscriber,
          )

          # Filter out parameters from SQL body.
          if ::ActiveRecord::Base.respond_to?(:connection_db_config)
            # Rails 6.1+ deprecates "connection_config" in favor of
            # "connection_db_config", so we need an updated call.
            Airbrake.add_performance_filter(
              Airbrake::Filters::SqlFilter.new(
                ::ActiveRecord::Base.connection_db_config.configuration_hash[:adapter],
              ),
            )
          else
            Airbrake.add_performance_filter(
              Airbrake::Filters::SqlFilter.new(
                ::ActiveRecord::Base.connection_config[:adapter],
              ),
            )
          end
        end
      end
    end
  end
end
