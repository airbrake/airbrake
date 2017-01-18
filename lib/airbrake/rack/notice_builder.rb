module Airbrake
  module Rack
    ##
    # A helper class for filling notices with all sorts of useful information
    # coming from the Rack environment.
    class NoticeBuilder
      @builders = []

      class << self
        ##
        # @return [Array<Proc>] the list of notice builders
        attr_reader :builders
      end

      ##
      # @param [Hash{String=>Object}] rack_env The Rack environment
      def initialize(rack_env, notifier_name = :default)
        @rack_env = rack_env
        @notifier_name = notifier_name
        @request = ::Rack::Request.new(rack_env)
      end

      ##
      # Adds context, session, params and other fields based on the Rack env.
      #
      # @param [Exception] exception
      # @return [Airbrake::Notice] the notice with extra information
      def build_notice(exception)
        return unless (notice = Airbrake.build_notice(exception, {}, @notifier_name))

        NoticeBuilder.builders.each { |builder| builder.call(notice, @request) }
        notice
      end
    end
  end
end
