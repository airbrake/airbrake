# frozen_string_literal: true

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
