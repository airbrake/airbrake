module ActionCable
  module Channel
    # Provides integration with ActionCable.
    class Base
      alias perform_action_without_airbrake perform_action

      def perform_action(*args, &block)
        perform_action_without_airbrake(*args, &block)
      rescue Exception => exception # rubocop:disable Lint/RescueException
        Airbrake.notify(exception) do |notice|
          notice.stash[:action_cable_connection] = connection
          notice[:context][:component] = 'action_cable'
          notice[:context][:action] = "#{self.class}##{args.first['action']}"
          notice[:params].merge!(args.first)
        end
        raise exception
      end
    end
  end
end
