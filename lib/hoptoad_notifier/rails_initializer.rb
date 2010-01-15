module HoptoadNotifier
  # used to initialize Rails-specific code
  class RailsInitializer
    def self.initialize
      rails_logger = if defined?(Rails.logger)
                       Rails.logger
                     elsif defined?(RAILS_DEFAULT_LOGGER)
                       RAILS_DEFAULT_LOGGER
                     end

      HoptoadNotifier.configure(true) do |config|
        config.logger = rails_logger
      end
    end
  end
end
