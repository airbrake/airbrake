# frozen_string_literal: true

RSpec.describe Airbrake::Rack do
  after { Airbrake::Rack::RequestStore.clear }

  describe ".capture_timing" do
    let(:routes) { Airbrake::Rack::RequestStore[:routes] }

    context "when request store doesn't have any routes" do
      it "doesn't store timing" do
        described_class.capture_timing('operation') {}
        expect(Airbrake::Rack::RequestStore.store).to be_empty
      end

      it "returns the value of the block" do
        expect(described_class.capture_timing('operation') { 1 }).to eq(1)
      end
    end

    context "when request store has a route" do
      before do
        Airbrake::Rack::RequestStore[:routes] = {
          '/about' => {
            method: 'GET',
            response_type: :html,
            groups: {},
          },
        }
      end

      it "attaches all timings for different operations to the request store" do
        described_class.capture_timing('operation 1') {}
        described_class.capture_timing('operation 2') {}
        described_class.capture_timing('operation 3') {}

        expect(routes['/about'][:groups]).to match(
          'operation 1' => be > 0,
          'operation 2' => be > 0,
          'operation 3' => be > 0,
        )
      end

      it "returns the value of the block" do
        expect(described_class.capture_timing('operation') { 1 }).to eq(1)
      end
    end
  end
end
