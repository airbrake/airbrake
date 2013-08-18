module Airbrake
  class UserInformer
    def initialize(app)
      @app = app
    end

    def replacement(with)
      Airbrake.configuration.user_information.gsub(/\{\{\s*error_id\s*\}\}/, with.to_s)
    end

    def call(env)
      dup._call(env)
    end

    def _call(env)
      status, headers, body = @app.call(env)

      if env['airbrake.error_id'] && Airbrake.configuration.user_information
        new_body = []
        replace  = replacement(env['airbrake.error_id'])
        body.each do |chunk|
          new_body << chunk.gsub("<!-- AIRBRAKE ERROR -->", replace)
        end
        body.close if body.respond_to?(:close)
        headers['Content-Length'] = new_body.inject(0){|sum, x| sum + x.bytesize}.to_s
        body = new_body
      end

      [status, headers, body]

    ensure
      body.close if body && body.respond_to?(:close) && $!
    end
  end
end

