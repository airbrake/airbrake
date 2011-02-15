module HoptoadNotifier
  class UserInformer
    def initialize(app)
      @app = app
    end

    def replacement(with)
      @replacement ||= HoptoadNotifier.configuration.user_information.gsub(/\{\{\s*error_id\s*\}\}/, with.to_s)
    end

    def call(env)
      status, headers, body = @app.call(env)
      if env['hoptoad.error_id']
        body.each_with_index do |chunk, i|
          body[i] = chunk.to_s.gsub("<!-- HOPTOAD ERROR -->", replacement(env['hoptoad.error_id']))
        end
        headers['Content-Length'] = body.sum(&:length).to_s
      end
      [status, headers, body]
    end
  end
end

