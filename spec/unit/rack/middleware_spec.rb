require 'spec_helper'

RSpec.describe Airbrake::Rack::Middleware do
  let(:app) { proc { |env| [200, env, 'Bingo bango content'] } }
  let(:faulty_app) { proc { raise AirbrakeTestError } }
  let(:endpoint) { 'https://airbrake.io/api/v3/projects/113743/notices' }
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

  describe "#new" do
    it "doesn't add filters if no notifiers are configured" do
      expect do
        expect(described_class.new(faulty_app, :unknown_notifier))
      end.not_to raise_error
    end
  end

  describe "#call" do
    context "when app raises an exception" do
      context "and when the notifier name is specified" do
        let(:notifier_name) { :rack_middleware_initialize }
        let(:bingo_endpoint) { 'https://airbrake.io/api/v3/projects/92123/notices' }
        let(:expected_body) { /"errors":\[{"type":"AirbrakeTestError"/ }

        before do
          Airbrake.configure(notifier_name) do |c|
            c.project_id = 92123
            c.project_key = 'ad04e13d806a90f96614ad8e529b2821'
            c.logger = Logger.new('/dev/null')
            c.app_version = '3.2.1'
          end

          stub_request(:post, bingo_endpoint).to_return(status: 201, body: '{}')
        end

        after { Airbrake[notifier_name].close }

        it "notifies via the specified notifier" do
          expect do
            described_class.new(faulty_app, notifier_name).call(env_for('/'))
          end.to raise_error(AirbrakeTestError)

          wait_for(
            a_request(:post, bingo_endpoint).
              with(body: expected_body)
          ).to have_been_made.once

          expect(
            a_request(:post, endpoint).
              with(body: expected_body)
          ).not_to have_been_made
        end
      end

      context "and when the notifier is not configured" do
        it "rescues the exception, notifies Airbrake & re-raises it" do
          expect { described_class.new(faulty_app).call(env_for('/')) }.
            to raise_error(AirbrakeTestError)

          wait_for_a_request_with_body(/"errors":\[{"type":"AirbrakeTestError"/)
        end

        it "sends framework version and name" do
          expect { described_class.new(faulty_app).call(env_for('/bingo/bango')) }.
            to raise_error(AirbrakeTestError)

          wait_for_a_request_with_body(
            /"context":{.*"versions":{"(rails|sinatra|rack_version)"/
          )
        end
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
      allow(Airbrake[:default]).to receive(:build_notice).and_return(nil)
      allow(Airbrake[:default]).to receive(:notify)

      expect { described_class.new(faulty_app).call(env_for('/')) }.
        to raise_error(AirbrakeTestError)

      expect(Airbrake[:default]).to have_received(:build_notice)
      expect(Airbrake[:default]).not_to have_received(:notify)
    end
  end
end
