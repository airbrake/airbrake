require 'sinatra'

require 'apps/sinatra/dummy_app'
require 'integration/shared_examples/rack_examples'

RSpec.describe "Sinatra integration specs" do
  let(:app) { DummyApp }

  include_examples 'rack examples'

  describe "context payload" do
    before { stub_request(:post, endpoint).to_return(status: 200, body: '') }

    it "includes version" do
      get '/crash'
      sleep 2

      body = /"context":{.*"versions":{"sinatra":"\d\./
      expect(a_request(:post, endpoint).with(body: body)).to have_been_made
    end

    it "includes route" do
      get '/crash'
      sleep 2

      body = %r("context":{.*"route":"\/crash".*})
      expect(a_request(:post, endpoint).with(body: body)).to have_been_made
    end
  end
end
