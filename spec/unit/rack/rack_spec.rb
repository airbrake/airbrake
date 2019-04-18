RSpec.describe Airbrake::Rack do
  describe ".capture_http_performance" do
    context "when request store doesn't have any routes" do
      before { Airbrake::Rack::RequestStore.clear }

      it "doesn't store http time" do
        described_class.capture_http_performance {}
        expect(Airbrake::Rack::RequestStore.store).to be_empty
      end

      it "returns what the given block returns" do
        expect(described_class.capture_http_performance { 1 }).to eq(1)
      end
    end

    context "when request store has a route" do
      let(:routes) { Airbrake::Rack::RequestStore[:routes] }

      before do
        Airbrake::Rack::RequestStore[:routes] = {
          '/about' => {
            method: 'GET',
            response_type: :html,
            groups: {}
          }
        }
      end

      after { Airbrake::Rack::RequestStore.clear }

      it "attaches http timing to the route" do
        described_class.capture_http_performance {}
        expect(routes['/about'][:groups][:http]).to be > 0
      end
    end
  end
end
