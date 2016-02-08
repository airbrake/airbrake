module Airbrake
  module Rack
    ##
    # Represents an authenticated user, which can be converted to Airbrake's
    # payload format. Supports Warden and Omniauth authentication frameworks.
    class User
      # Finds the user in the Rack environment and creates a new user wrapper.
      #
      # @param [Hash{String=>Object}] rack_env The Rack environment
      # @return [Airbrake::Rack::User, nil]
      def self.extract(rack_env)
        # Warden support (including Devise).
        if (warden = rack_env['warden'])
          if (user = warden.user(run_callbacks: false))
            return new(user) if user
          end
        end

        # Fallback mode (OmniAuth support included). Works only for Rails.
        controller = rack_env['action_controller.instance']
        return unless controller.respond_to?(:current_user)
        new(controller.current_user) if controller.current_user
      end

      def initialize(user)
        @user = user
      end

      def as_json
        user = {}

        user[:id] = try_to_get(:id)
        user[:name] = full_name
        user[:username] = try_to_get(:username)
        user[:email] = try_to_get(:email)

        user = user.delete_if { |_key, val| val.nil? }
        user.empty? ? user : { user: user }
      end

      private

      def try_to_get(key)
        String(@user.__send__(key)) if @user.respond_to?(key)
      end

      def full_name
        # Try to get first and last names. If that fails, try to get just 'name'.
        name = [try_to_get(:first_name), try_to_get(:last_name)].compact.join(' ')
        name.empty? ? try_to_get(:name) : name
      end
    end
  end
end
