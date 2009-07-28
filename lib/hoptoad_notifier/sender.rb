module HoptoadNotifier
  class Sender
    def send_to_hoptoad(data) #:nodoc:
      url = HoptoadNotifier.url
      http = Net::HTTP::Proxy(HoptoadNotifier.proxy_host,
                              HoptoadNotifier.proxy_port,
                              HoptoadNotifier.proxy_user,
                              HoptoadNotifier.proxy_pass).new(url.host, url.port)

      http.use_ssl = true
      http.read_timeout = HoptoadNotifier.http_read_timeout
      http.open_timeout = HoptoadNotifier.http_open_timeout
      http.use_ssl = !!HoptoadNotifier.secure

      response = begin
                   http.post(url.path, stringify_keys(data).to_yaml, HEADERS)
                 rescue TimeoutError => e
                   log :error, "Timeout while contacting the Hoptoad server."
                   nil
                 end

      case response
      when Net::HTTPSuccess then
        log :info, "Success: #{response.class}", response
      else
        log :error, "Failure: #{response.class}", response
      end
    end

    private

    def stringify_keys(hash) #:nodoc:
      hash.inject({}) do |h, pair|
        h[pair.first.to_s] = pair.last.is_a?(Hash) ? stringify_keys(pair.last) : pair.last
        h
      end
    end

    def log(level, message, response = nil)
      logger.send level, LOG_PREFIX + message if logger
      HoptoadNotifier.report_environment_info
      HoptoadNotifier.report_response_body(response.body) if response && response.respond_to?(:body)
    end

    def logger
      HoptoadNotifier.logger
    end

  end
end
