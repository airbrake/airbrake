class SinatraTestApp < Sinatra::Base
  use Airbrake::Rack::Middleware
  use Warden::Manager

  get '/' do
    'Hello from index'
  end

  get '/crash' do
    raise AirbrakeTestError
  end
end

Airbrake::Rack.add_default_filters
