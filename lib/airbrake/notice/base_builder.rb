module Airbrake
  class Notice
    class BaseBuilder
      def self.render(notice)
        new(notice).render
      end

      attr_reader :notice

      ATTRIBUTES_TO_RENDER = %w(
        backtrace
        notifier_name
        notifier_version
        notifier_url
        api_key
        error_message
        error_class
        request_present?
        url
        controller
        action
        parameters
        session_data
        cgi_data
        project_root
        environment_name
        hostname
        user
        framework
      )

      ATTRIBUTES_TO_RENDER.each do |attr|
        define_method attr do
          notice.send(attr)
        end
      end

      def initialize(notice)
        @notice = notice
      end
    end
  end
end
