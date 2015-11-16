require 'multi_json'
require 'airbrake/notice/base_builder'

module Airbrake
  class Notice
    class JsonBuilder < BaseBuilder
      def render
        MultiJson.dump({
          'notifier' => {
            'name'    => 'airbrake',
            'version' => Airbrake::VERSION,
            'url'     => 'https://github.com/airbrake/airbrake'
          },
          'errors' => [{
            'type'       => error_class,
            'message'    => error_message,
            'backtrace'  => backtrace.lines.map do |line|
              {
                'file'     => line.file,
                'line'     => line.number.to_i,
                'function' => line.method_name
              }
            end
          }],
          'context' => {}.tap do |hash|
            if request_present?
              hash['url']           = url
              hash['component']     = controller
              hash['action']        = action
              hash['rootDirectory'] = File.dirname(project_root)
              hash['environment']   = environment_name
            end
          end.tap do |hash|
            next if user.empty?

            hash['userId']    = user[:id]
            hash['userName']  = user[:name]
            hash['userEmail'] = user[:email]
          end

        }.tap do |hash|
          hash['environment'] = cgi_data     unless cgi_data.empty?
          hash['params']      = parameters   unless parameters.empty?
          hash['session']     = session_data unless session_data.empty?
        end)
      end
    end
  end
end


