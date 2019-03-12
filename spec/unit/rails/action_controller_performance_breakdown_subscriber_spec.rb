require 'airbrake/rails/action_controller_performance_breakdown_subscriber'

RSpec.describe Airbrake::Rails::ActionControllerPerformanceBreakdownSubscriber do
  after { Airbrake::Rack::RequestStore.clear }

  context "when routes are not set in the request store" do
    before { Airbrake::Rack::RequestStore[:routes] = nil }

    it "doesn't send performance breakdown info" do
      expect(Airbrake).not_to receive(:notify_performance_breakdown)
      subject.call([])
    end
  end

  context "when there are no routes in the request store" do
    before { Airbrake::Rack::RequestStore[:routes] = [] }

    it "doesn't send performance breakdown info" do
      expect(Airbrake).not_to receive(:notify_performance_breakdown)
      subject.call([])
    end
  end

  context "when there's a route in the request store" do
    let(:event) do
      OpenStruct.new(
        payload: {
          format: :html,
          view_runtime: 0.5,
          db_runtime: 0.5
        }
      )
    end

    before do
      Airbrake::Rack::RequestStore[:routes] = [['/test-route', 'GET']]

      event_dbl = double
      expect(event_dbl).to receive(:new).and_return(event)
      stub_const('ActiveSupport::Notifications::Event', event_dbl)
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

    context "and when view_runtime is nil" do
      before { event.payload[:view_runtime] = nil }

      it "sets the view group runtime to 0" do
        expect(Airbrake).to receive(:notify_performance_breakdown).with(
          hash_including(
            route: '/test-route',
            method: 'GET',
            response_type: :html,
            groups: { db: 0.5, view: 0 }
          )
        )
        subject.call([])
      end
    end

    context "and when db_runtime is nil" do
      before { event.payload[:db_runtime] = nil }

      it "sets the view group runtime to 0" do
        expect(Airbrake).to receive(:notify_performance_breakdown).with(
          hash_including(
            route: '/test-route',
            method: 'GET',
            response_type: :html,
            groups: { db: 0, view: 0.5 }
          )
        )
        subject.call([])
      end
    end
  end
end
