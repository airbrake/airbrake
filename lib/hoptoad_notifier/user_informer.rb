module HoptoadNotifier
  class UserInformer
    def initialize(app)
      @app = app
    end

    def replacement(with)
      @replacement ||= HoptoadNotifier.configuration.user_information.gsub(/\{\{\s*error_id\s*\}\}/, with.to_s)
    end

    def call(env)
      response = @app.call(env)
      if env['hoptoad.error_id']
        new_response = []
        original_content_length = 0
        modified_content_length = 0
        response[2].each do |chunk|
          original_content_length += chunk.length
          new_response << chunk.to_s.gsub("<!-- HOPTOAD ERROR -->", replacement(env['hoptoad.error_id']))
          modified_content_length += new_response.last.length
        end
        response[1]['Content-Length'] = modified_content_length.to_s
        response[2] = new_response
      end
      response
    end
  end
end

