require 'airbrake/rails/action_controller_notify_subscriber'

RSpec.describe Airbrake::Rails::ActionControllerNotifySubscriber do
  after { Airbrake::Rack::RequestStore.clear }

  describe "#call" do
    let(:event) { double(Airbrake::Rails::Event) }

    before do
      allow(Airbrake::Rails::Event).to receive(:new).and_return(event)
    end

    context "when there are no routes in the request store" do
      it "doesn't notify requests" do
        expect(Airbrake).not_to receive(:notify_request)
        subject.call([])
      end
    end

    context "when there's a route in the request store" do
      before do
        Airbrake::Rack::RequestStore[:routes] = {
          '/test-route' => { method: 'GET', response_type: :html },
        }

        expect(event).to receive(:method).and_return('GET')
        expect(event).to receive(:status_code).and_return(200)
        expect(event).to receive(:time).and_return(Time.now)
        expect(event).to receive(:duration).and_return(1.234)
      end

      it "sends request info to Airbrake" do
        expect(Airbrake).to receive(:notify_request).with(
          hash_including(
            method: 'GET',
            route: '/test-route',
            status_code: 200,
          ),
        )
        subject.call([])
      end
    end
  end
end
