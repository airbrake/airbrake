require 'sinatra'
require 'spec_helper'

require 'apps/sinatra/dummy_app'
require 'apps/sinatra/composite_app/sinatra_app1'
require 'apps/sinatra/composite_app/sinatra_app2'

require 'integration/shared_examples/rack_examples'

RSpec.describe "Sinatra integration specs" do
  let(:app) { DummyApp }

  include_examples 'rack examples'

  describe "context payload" do
    it "includes version" do
      get '/crash'
      wait_for_a_request_with_body(/"context":{.*"versions":{"sinatra":"\d\./)
    end
  end

  context "when multiple apps are mounted" do
    let(:endpoint1) { 'https://airbrake.io/api/v3/projects/113743/notices' }
    let(:endpoint2) { 'https://airbrake.io/api/v3/projects/99123/notices' }

    def env_for(url, opts = {})
      Rack::MockRequest.env_for(url, opts)
    end

    before do
      stub_request(:post, endpoint1).to_return(status: 201, body: '{}')
      stub_request(:post, endpoint2).to_return(status: 201, body: '{}')
    end

    context "and when both apps use their own notifiers and middlewares" do
      let(:app) do
        Rack::Builder.new do
          map('/app1') do
            use Airbrake::Rack::Middleware, SinatraApp1
            run SinatraApp1.new
          end

          map '/app2' do
            use Airbrake::Rack::Middleware, SinatraApp2
            run SinatraApp2.new
          end
        end
      end

      it "reports errors from SinatraApp1 notifier" do
        get '/app1'

        body = %r|"backtrace":\[{"file":".+apps/sinatra/composite_app/sinatra_app1.rb"|

        wait_for(
          a_request(:post, endpoint1).
            with(body: body)
        ).to have_been_made.once
      end

      it "reports errors from SinatraApp2 notifier" do
        get '/app2'

        body = %r|"backtrace":\[{"file":".+apps/sinatra/composite_app/sinatra_app2.rb"|
        wait_for(
          a_request(:post, endpoint2).
            with(body: body)
        ).to have_been_made.once
      end
    end
  end
end
