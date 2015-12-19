module Airbrake
  module Rack
    ##
    # Represents an authenticated Warden user, which can be converted to
    # Airbrake's payload format.
    class User
      # Finds the Warden user in the Rack environment and creates a new user
      # wrapper.
      #
      # @param [Hash{String=>Object}] rack_env The Rack environment
      # @return [Airbrake::Rack::User, nil]
      def self.extract(rack_env)
        return unless (warden = rack_env['warden'])
        new(warden.user(run_callbacks: false))
      end

      ##
      # @param [Warden::Proxy] warden_user
      def initialize(warden_user)
        @warden_user = warden_user
      end

      ##
      # Converts the user to Airbrake payload user.
      # @return [Hash{Symbol=>String}] the hash with retrieved user details
      def to_hash
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
        String(@warden_user.__send__(key)) if @warden_user.respond_to?(key)
      end

      def full_name
        # Try to get first and last names. If that fails, try to get just 'name'.
        name = [try_to_get(:first_name), try_to_get(:last_name)].compact.join(' ')
        name.empty? ? try_to_get(:name) : name
      end
    end
  end
end
