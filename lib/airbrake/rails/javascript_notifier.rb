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
          if Airbrake.configuration.public?
            airbrake_javascript_loader + airbrake_javascript_configuration
          end
        end

        def airbrake_javascript_loader
          if Airbrake.configuration.public?
            path = File.join File.dirname(__FILE__), '..', '..', 'templates', 'javascript_notifier_loader'

            _airbrake_render_part path
          end
        end

        def airbrake_javascript_configuration
          if Airbrake.configuration.public?
            path = File.join File.dirname(__FILE__), '..', '..', 'templates', 'javascript_notifier_configuration'

            options              = {
              :api_key         => Airbrake.configuration.js_api_key,
              :environment     => Airbrake.configuration.environment_name,
              :action_name     => action_name,
              :controller_name => controller_name,
              :url             => request.url
            }

            _airbrake_render_part path, options
          end
        end

      protected
        attr_reader :template

        def _airbrake_render_part(path, locals={})
          locals[:host] = _airbrake_host

          options              = {
            :file              => path,
            :layout            => false,
            :use_full_path     => false,
            :handlers          => [:erb],
            :locals            => locals
          }

          result = _airbrake_render_template options

          if result.respond_to?(:html_safe)
            result.html_safe
          else
            result
          end
        end

        def _airbrake_render_template(options)
          case template
          when ActionView::Template
            template.render options
          else
            render_to_string options
          end
        end

        def _airbrake_host
          host = Airbrake.configuration.host.dup
          port = Airbrake.configuration.port
          host << ":#{port}" unless [80, 443].include?(port)

          host
        end
    end
  end
end
