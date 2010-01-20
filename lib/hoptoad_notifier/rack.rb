module HoptoadNotifier
  class Rack
    def initialize(app)
      @app = app
    end

    def call(env)
      begin
        response = @app.call(env)
      rescue Exception => raised
        HoptoadNotifier.notify_or_ignore(raised, :rack_env => env)
        raise
      end

      if env['rack.exception']
        HoptoadNotifier.notify_or_ignore(env['rack.exception'], :rack_env => env)
      end

      response
    end
  end
end
