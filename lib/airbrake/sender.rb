module Airbrake
  # Sends out the notice to Airbrake
  class Sender

    NOTICES_URI = '/notifier_api/v2/notices'.freeze
    HEADERS = {
      :xml => {
      'Content-type' => 'text/xml',
      'Accept'       => 'text/xml, application/xml'
    },:json => {
      'Content-Type' => 'application/json',
      'Accept'       => 'application/json'
    }}

    JSON_API_URI = '/api/v3/projects'.freeze
    HTTP_ERRORS = [Timeout::Error,
                   Errno::EINVAL,
                   Errno::ECONNRESET,
                   EOFError,
                   Net::HTTPBadResponse,
                   Net::HTTPHeaderSyntaxError,
                   Net::ProtocolError,
                   Errno::ECONNREFUSED,
                   OpenSSL::SSL::SSLError].freeze

    def initialize(options = {})
      [ :proxy_host,
        :proxy_port,
        :proxy_user,
        :proxy_pass,
        :protocol,
        :host,
        :port,
        :secure,
        :use_system_ssl_cert_chain,
        :http_open_timeout,
        :http_read_timeout,
        :project_id,
        :api_key
      ].each do |option|
        instance_variable_set("@#{option}", options[option])
      end
    end


    # Sends the notice data off to Airbrake for processing.
    #
    # @param [Notice or String] notice The notice to be sent off
    def send_to_airbrake(notice)
      data = prepare_notice(notice)
      http = setup_http_connection

      response = begin
                   http.post(url.respond_to?(:path) ? url.path : url,
                             data,
                             headers)
                 rescue *HTTP_ERRORS => e
                   log :level => :error,
                       :message => "Unable to contact the Airbrake server. HTTP Error=#{e}"
                   nil
                 end

      case response
      when Net::HTTPSuccess then
        log :level => :info,
            :message => "Success: #{response.class}",
            :response => response
      else
        log :level => :error,
            :message => "Failure: #{response.class}",
            :response => response,
            :notice => notice
      end

      if response && response.respond_to?(:body)
        error_id = response.body.match(%r{<id[^>]*>(.*?)</id>})
        error_id[1] if error_id
      end
    rescue => e
      log :level => :error,
        :message => "[Airbrake::Sender#send_to_airbrake] Cannot send notification. Error: #{e.class}" +
        " - #{e.message}\nBacktrace:\n#{e.backtrace.join("\n\t")}"

      nil
    end

    attr_reader :proxy_host,
                :proxy_port,
                :proxy_user,
                :proxy_pass,
                :protocol,
                :host,
                :port,
                :secure,
                :use_system_ssl_cert_chain,
                :http_open_timeout,
                :http_read_timeout,
                :project_id,
                :api_key

    alias_method :secure?, :secure
    alias_method :use_system_ssl_cert_chain?, :use_system_ssl_cert_chain

  private

    def prepare_notice(notice)
      if json_api_enabled?
        begin
          JSON.parse(notice)
          notice
        rescue
          notice.to_json
        end
      else
        notice.respond_to?(:to_xml) ? notice.to_xml : notice
      end
    end

    def api_url
      if json_api_enabled?
        "#{JSON_API_URI}/#{project_id}/notices?key=#{api_key}"
      else
        NOTICES_URI
      end
    end

    def headers
      if json_api_enabled?
        HEADERS[:json]
      else
        HEADERS[:xml]
      end
    end

    def url
      URI.parse("#{protocol}://#{host}:#{port}").merge(api_url)
    end

    def log(opts = {})
      (opts[:logger] || logger).send(opts[:level], LOG_PREFIX + opts[:message])
      Airbrake.report_environment_info
      Airbrake.report_response_body(opts[:response].body) if opts[:response] && opts[:response].respond_to?(:body)
      Airbrake.report_notice(opts[:notice]) if opts[:notice]
    end

    def logger
      Airbrake.logger
    end

    def setup_http_connection
      http =
        Net::HTTP::Proxy(proxy_host, proxy_port, proxy_user, proxy_pass).
        new(url.host, url.port)

      http.read_timeout = http_read_timeout
      http.open_timeout = http_open_timeout

      if secure?
        http.use_ssl     = true

        http.ca_file      = Airbrake.configuration.ca_bundle_path
        http.verify_mode  = OpenSSL::SSL::VERIFY_PEER
      else
        http.use_ssl     = false
      end

      http
    rescue => e
      log :level => :error,
          :message => "[Airbrake::Sender#setup_http_connection] Failure initializing the HTTP connection.\n" +
                      "Error: #{e.class} - #{e.message}\nBacktrace:\n#{e.backtrace.join("\n\t")}"
      raise e
    end

    def json_api_enabled?
      !!(host =~ /collect.airbrake.io/) &&
        project_id =~ /\S/
    end
  end

  class CollectingSender < Sender
    # Used when test mode is enabled, to store the last XML notice locally

    attr_writer :last_notice_path

    def last_notice
      File.read last_notice_path
    end

    def last_notice_path
      File.expand_path(File.join("..", "..", "..", "resources", "notice.xml"), __FILE__)
    end

    def send_to_airbrake(notice)
      data = prepare_notice(notice)

      notices_file = File.open(last_notice_path, "w") do |file|
        file.puts data
      end

      super(notice)
    ensure
      notices_file.close if notices_file
    end
  end
end
