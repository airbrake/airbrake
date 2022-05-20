# frozen_string_literal: true

require 'airbrake/rails/action_controller_notify_subscriber'

RSpec.describe Airbrake::Rails::ActionControllerNotifySubscriber do
  subject(:subscriber) { described_class.new }

  after { Airbrake::Rack::RequestStore.clear }

  describe "#call" do
    let(:event) { double(Airbrake::Rails::Event) }

    before do
      allow(Airbrake::Rails::Event).to receive(:new).and_return(event)
      allow(Airbrake).to receive(:notify_request)
    end

    context "when there are no routes in the request store" do
      it "doesn't notify requests" do
        subscriber.call([])
        expect(Airbrake).not_to have_received(:notify_request)
      end
    end

    context "when there's a route in the request store" do
      before do
        Airbrake::Rack::RequestStore[:routes] = {
          '/test-route' => { method: 'GET', response_type: :html },
        }

        allow(event).to receive(:method).and_return('GET')
        allow(event).to receive(:status_code).and_return(200)
        allow(event).to receive(:time).and_return(Time.now)
        allow(event).to receive(:duration).and_return(1.234)
      end

      context "and when the Airbrake config disables performance stats" do
        before do
          allow(Airbrake::Config.instance)
            .to receive(:performance_stats).and_return(false)
        end

        it "doesn't notify requests" do
          subscriber.call([])
          expect(Airbrake).not_to have_received(:notify_request)
        end
      end

      context "and when the Airbrake config enables performance stats" do
        let(:timestamp) { Time.now.to_f }

        before do
          allow(Airbrake::Config.instance)
            .to receive(:performance_stats).and_return(true)

          allow(event).to receive(:method).and_return('GET')
          allow(event).to receive(:status_code).and_return(200)
          allow(event).to receive(:time).and_return(timestamp)
          allow(event).to receive(:duration).and_return(1.234)
        end

        it "sends request info to Airbrake" do
          subscriber.call([])

          expect(Airbrake).to have_received(:notify_request).with(
            hash_including(
              method: 'GET',
              route: '/test-route',
              status_code: 200,
              time: timestamp,
            ),
          )
          expect(event).to have_received(:method)
          expect(event).to have_received(:status_code)
          expect(event).to have_received(:time)
          expect(event).to have_received(:duration)
        end
      end
    end
  end
end
