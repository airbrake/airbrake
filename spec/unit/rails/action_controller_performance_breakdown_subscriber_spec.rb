require 'airbrake/rails/action_controller_performance_breakdown_subscriber'

RSpec.describe Airbrake::Rails::ActionControllerPerformanceBreakdownSubscriber do
  let(:app) { double(Airbrake::Rails::App) }
  let(:event) { double(Airbrake::Rails::Event) }

  before do
    allow(Airbrake::Rails::Event).to receive(:new).and_return(event)
  end

  after { Airbrake::Rack::RequestStore.clear }

  context "when routes are not set in the request store" do
    before { Airbrake::Rack::RequestStore[:routes] = nil }

    it "doesn't send performance breakdown info" do
      expect(Airbrake).not_to receive(:notify_performance_breakdown)
      subject.call([])
    end
  end

  context "when there are no routes in the request store" do
    before { Airbrake::Rack::RequestStore[:routes] = {} }

    it "doesn't send performance breakdown info" do
      expect(Airbrake).not_to receive(:notify_performance_breakdown)
      subject.call([])
    end
  end

  context "when there's a route in the request store" do
    before do
      Airbrake::Rack::RequestStore[:routes] = {
        '/test-route' => { method: 'GET', response_type: :html }
      }

      expect(event).to receive(:groups).and_return(db: 0.5, view: 0.5)
      expect(event).to receive(:method).and_return('GET')
      expect(event).to receive(:response_type).and_return(:html)
      expect(event).to receive(:time).and_return(Time.new)
    end

    it "sends performance info to Airbrake" do
      expect(Airbrake).to receive(:notify_performance_breakdown).with(
        hash_including(
          route: '/test-route',
          method: 'GET',
          response_type: :html,
          groups: { db: 0.5, view: 0.5 }
        )
      )
      subject.call([])
    end
  end
end
