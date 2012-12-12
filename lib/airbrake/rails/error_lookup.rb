module Airbrake
  module Rails
    module ErrorLookup

      # Sets up an alias chain to catch exceptions when Rails does
      def self.included(base) #:nodoc:
        if base.method_defined?(:rescue_action_locally)
          base.send(:alias_method, :rescue_action_locally_without_airbrake, :rescue_action_locally)
          base.send(:alias_method, :rescue_action_locally, :rescue_action_locally_with_airbrake)
        end
      end

      private

      def rescue_action_locally_with_airbrake(exception)
        result = rescue_action_locally_without_airbrake(exception)

        if Airbrake.configuration.development_lookup
          path   = File.join(File.dirname(__FILE__), '..', '..', 'templates', 'rescue.erb')
          notice = Airbrake.build_lookup_hash_for(exception, airbrake_request_data)

          result << @template.render(
            :file          => path,
            :use_full_path => false,
            :locals        => { :host    => Airbrake.configuration.host,
                                :api_key => Airbrake.configuration.api_key,
                                :notice  => notice })
        end

        result
      end
    end
  end
end

