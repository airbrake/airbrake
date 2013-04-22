module Airbrake
  module Rails
    module JavascriptNotifier
      def self.included(base) #:nodoc:
        base.send :helper_method, :airbrake_javascript_notifier
      end

      private

      def airbrake_javascript_notifier_options
        path = File.join File.dirname(__FILE__), '..', '..', 'templates', 'javascript_notifier'
        host = Airbrake.configuration.host.dup
        port = Airbrake.configuration.port
        host << ":#{port}" unless [80, 443].include?(port)

        options              = {
          :file              => path,
          :layout            => false,
          :use_full_path     => false,
          :handlers          => [:erb],
          :locals            => {
            :host            => host,
            :api_key         => Airbrake.configuration.js_api_key,
            :environment     => Airbrake.configuration.environment_name,
            :action_name     => action_name,
            :controller_name => controller_name,
            :url             => request.url
          }
        }
      end

      def airbrake_javascript_notifier
        return unless Airbrake.configuration.public?

        options = airbrake_javascript_notifier_options

        result  = airbrake_compile_template

        if result.respond_to?(:html_safe)
          result.html_safe
        else
          result
        end
      end

      def airbrake_compile_template
        case @template
        when ActionView::Template
          @template.render airbrake_javascript_notifier_options
        else
          render_to_string airbrake_javascript_notifier_options
        end
      end
    end
  end
end
