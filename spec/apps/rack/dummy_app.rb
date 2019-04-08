DummyApp = Rack::Builder.new do
  use Rack::ShowExceptions
  use Airbrake::Rack::Middleware
  use Warden::Manager

  map '/' do
    run(
      proc do |_env|
        [200, { 'Content-Type' => 'text/plain' }, ['Hello from index']]
      end
    )
  end

  map '/crash' do
    run(proc { |_env| raise AirbrakeTestError })
  end
end
