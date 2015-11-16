require 'builder'

module Airbrake
  class Notice
    class XmlBuilder
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

      def render
        builder = Builder::XmlMarkup.new
        builder.instruct!
        xml = builder.notice(:version => Airbrake::API_VERSION) do |notice|
          notice.tag!("api-key", api_key)
          notice.notifier do |notifier|
            notifier.name(notifier_name)
            notifier.version(notifier_version)
            notifier.url(notifier_url)
          end
          notice.tag!('error') do |error|
            error.tag!('class', error_class)
            error.message(error_message)
            error.backtrace do |backtrace|
              self.backtrace.lines.each do |line|
                backtrace.line(
                  :number      => line.number,
                  :file        => line.file,
                  :method      => line.method_name
                )
              end
            end
          end

          if request_present?
            notice.request do |request|
              request.url(url)
              request.component(controller)
              request.action(action)
              unless parameters.empty?
                request.params do |params|
                  xml_vars_for(params, parameters)
                end
              end
              unless session_data.empty?
                request.session do |session|
                  xml_vars_for(session, session_data)
                end
              end
              unless cgi_data.empty?
                request.tag!("cgi-data") do |cgi_datum|
                  xml_vars_for(cgi_datum, cgi_data)
                end
              end
            end
          end
          notice.tag!("server-environment") do |env|
            env.tag!("project-root", project_root)
            env.tag!("environment-name", environment_name)
            env.tag!("hostname", hostname)
          end
          unless user.empty?
            notice.tag!("current-user") do |u|
              user.each do |attr, value|
                u.tag!(attr.to_s, value)
              end
            end
          end
          if framework =~ /\S/
            notice.tag!("framework", framework)
          end
        end
        xml.to_s
      end

      private

      def xml_vars_for(builder, hash)
        hash.each do |key, value|
          if value.respond_to?(:to_hash)
            builder.var(:key => key){|b| xml_vars_for(b, value.to_hash) }
          else
            builder.var(value.to_s, :key => key)
          end
        end
      end
    end
  end
end
