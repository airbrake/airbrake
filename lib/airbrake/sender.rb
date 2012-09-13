module Airbrake
  # Sends out the notice to Airbrake
  class Sender

    NOTICES_URI = '/notifier_api/v2/notices/'.freeze
    HTTP_ERRORS = [Timeout::Error,
                   Errno::EINVAL,
                   Errno::ECONNRESET,
                   EOFError,
                   Net::HTTPBadResponse,
                   Net::HTTPHeaderSyntaxError,
                   Net::ProtocolError,
                   Errno::ECONNREFUSED].freeze

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
        :http_read_timeout
      ].each do |option|
        instance_variable_set("@#{option}", options[option])
      end
    end

    # Sends the notice data off to Airbrake for processing.
    #
    # @param [Notice or String] notice The notice to be sent off
    def send_to_airbrake(notice)
      data = notice.respond_to?(:to_xml) ? notice.to_xml : notice
      http = setup_http_connection

      response = begin
                   http.post(url.path, data, HEADERS)
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
                :http_read_timeout

    alias_method :secure?, :secure
    alias_method :use_system_ssl_cert_chain?, :use_system_ssl_cert_chain

  private

    def url
      URI.parse("#{protocol}://#{host}:#{port}").merge(NOTICES_URI)
    end

    def log(opts = {})
      opts[:logger].send opts[:level], LOG_PREFIX + opts[:message] if opts[:logger]
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
  end
end
