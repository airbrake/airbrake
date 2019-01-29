require 'spec_helper'
require 'integration/shared_examples/rack_examples'

RSpec.describe "Rack integration specs" do
  let(:app) { DummyApp }

  include_examples 'rack examples'

  describe "context payload" do
    let(:endpoint) do
      'https://api.airbrake.io/api/v3/projects/113743/notices'
    end

    let(:routes_endpoint) do
      'https://api.airbrake.io/api/v5/projects/113743/routes-stats'
    end

    let(:queries_endpoint) do
      'https://api.airbrake.io/api/v5/projects/113743/queries-stats'
    end

    # Airbrake Ruby has a background thread that sends performance requests
    # periodically. We don't want this to get in the way.
    before do
      allow(Airbrake.notifiers[:performance][:default]).
        to receive(:notify).and_return(nil)

      stub_request(:post, endpoint).to_return(status: 200, body: '')
      [routes_endpoint, queries_endpoint].each do |endpoint|
        stub_request(:put, endpoint).to_return(status: 200, body: '')
      end
    end

    it "includes version" do
      get '/crash'
      wait_for_a_request_with_body(
        /"context":{.*"versions":{"rack_version":"\d\..+","rack_release":"\d\..+"}/
      )
    end
  end
end
