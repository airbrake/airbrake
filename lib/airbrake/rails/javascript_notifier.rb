module Airbrake
  module Rails
    module JavascriptNotifier
      def self.included(base) #:nodoc:
        base.send :helper_method, :airbrake_javascript_notifier
        base.send :helper_method, :airbrake_javascript_loader
        base.send :helper_method, :airbrake_javascript_configuration
      end

      private

      def airbrake_javascript_notifier
        airbrake_javascript_loader + airbrake_javascript_configuration
      end

      def airbrake_javascript_loader
        return unless Airbrake.configuration.public?

        path = File.join File.dirname(__FILE__), '..', '..', 'templates', 'javascript_notifier_loader.erb'

        render_part path, :host => host
      end

      def airbrake_javascript_configuration
        return unless Airbrake.configuration.public?

        path = File.join File.dirname(__FILE__), '..', '..', 'templates', 'javascript_notifier_configuration.erb'

        options              = {
          :host            => host,
          :api_key         => Airbrake.configuration.js_api_key,
          :environment     => Airbrake.configuration.environment_name,
          :action_name     => action_name,
          :controller_name => controller_name,
          :url             => request.url
        }

        render_part path, options
      end

    protected
      def render_part(path, locals={})
        options              = {
          :file              => path,
          :layout            => false,
          :use_full_path     => false,
          :locals            => locals
        }

        res = if @template
          @template.render(options)
        else
          render_to_string(options)
        end

        if res.respond_to?(:html_safe)
          res.html_safe
        else
          res
        end

      end

      def host
        host = Airbrake.configuration.host.dup
        port = Airbrake.configuration.port
        host << ":#{port}" unless [80, 443].include?(port)
      end
    end
  end
end
