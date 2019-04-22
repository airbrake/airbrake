# Monkey-patch to measure request timing.
class HTTPClient
  alias do_get_without_airbrake do_get_block

  def do_get_block(request, proxy, connection, &block)
    Airbrake::Rack.capture_http_performance do
      do_get_without_airbrake(request, proxy, connection, &block)
    end
  end
end
