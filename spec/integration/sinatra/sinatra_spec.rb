require 'sinatra'
require 'spec_helper'

require 'apps/sinatra/dummy_app'
require 'integration/shared_examples/rack_examples'

RSpec.describe "Sinatra integration specs" do
  let(:app) { DummyApp }

  include_examples 'rack examples'

  describe "context payload" do
    it "includes version" do
      get '/crash'
      wait_for_a_request_with_body(/"context":{.*"versions":{"sinatra":"\d\./)
    end

    it "includes route" do
      get '/crash'
      wait_for_a_request_with_body(%r("context":{.*"route":"\/crash".*}))
    end
  end
end
