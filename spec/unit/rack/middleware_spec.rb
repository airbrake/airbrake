require 'spec_helper'

RSpec.describe Airbrake::Rack::Middleware do
  let(:app) do
    proc { |env| [200, env, 'Bingo bango content'] }
  end

  let(:faulty_app) do
    proc { raise AirbrakeTestError }
  end

  let(:endpoint) do
    'https://airbrake.io/api/v3/projects/113743/notices?key=fd04e13d806a90f96614ad8e529b2822'
  end

  let(:middleware) { described_class.new(app) }

  def env_for(url, opts = {})
    Rack::MockRequest.env_for(url, opts)
  end

  def wait_for_a_request_with_body(body)
    wait_for(a_request(:post, endpoint).with(body: body)).to have_been_made.once
  end

  before do
    stub_request(:post, endpoint).to_return(status: 201, body: '{}')
  end

  describe "#call" do
    context "when app raises an exception" do
      it "rescues the exception, notifies Airbrake & re-raises it" do
        expect { described_class.new(faulty_app).call(env_for('/')) }.
          to raise_error(AirbrakeTestError)

        wait_for_a_request_with_body(/"errors":\[{"type":"AirbrakeTestError"/)
      end

      it "sends framework version and name" do
        expect { described_class.new(faulty_app).call(env_for('/bingo/bango')) }.
          to raise_error(AirbrakeTestError)

        wait_for_a_request_with_body(
          %r("context":{.*"version":"1.2.3 (Rails|Sinatra|Rack\.version)/.+".+})
        )
      end
    end

    context "when app doesn't raise" do
      context "and previous middleware stored an exception in env" do
        shared_examples 'stored exception' do |type|
          it "notifies on #{type}, but doesn't raise" do
            env = env_for('/').merge(type => AirbrakeTestError.new)
            described_class.new(app).call(env)

            wait_for_a_request_with_body(/"errors":\[{"type":"AirbrakeTestError"/)
          end
        end

        ['rack.exception', 'action_dispatch.exception', 'sinatra.error'].each do |type|
          include_examples 'stored exception', type
        end
      end

      it "doesn't notify Airbrake" do
        described_class.new(app).call(env_for('/'))
        sleep 1
        expect(a_request(:post, endpoint)).not_to have_been_made
      end
    end

    it "returns a response" do
      response =  described_class.new(app).call(env_for('/'))

      expect(response[0]).to eq(200)
      expect(response[1]).to be_a(Hash)
      expect(response[2]).to eq('Bingo bango content')
    end
  end

  context "when Airbrake is not configured" do
    it "returns nil" do
      allow(Airbrake).to receive(:build_notice).and_return(nil)
      allow(Airbrake).to receive(:notify)

      expect { described_class.new(faulty_app).call(env_for('/')) }.
        to raise_error(AirbrakeTestError)

      expect(Airbrake).to have_received(:build_notice)
      expect(Airbrake).not_to have_received(:notify)
    end
  end
end
