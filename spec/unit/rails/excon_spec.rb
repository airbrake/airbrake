# frozen_string_literal: true

require 'airbrake/rails/excon_subscriber'

RSpec.describe Airbrake::Rails::Excon do
  after { Airbrake::Rack::RequestStore.clear }

  let(:event) { double(Airbrake::Rails::Event) }

  before do
    allow(Airbrake::Rails::Event).to receive(:new).and_return(event)
  end

  context "when there are no routes in the request store" do
    it "doesn't notify requests" do
      expect(Airbrake).not_to receive(:notify_performance_breakdown)
      subject.call([])
    end
  end

  context "when there's a route in the request store" do
    let(:route) { Airbrake::Rack::RequestStore[:routes]['/test-route'] }

    before do
      Airbrake::Rack::RequestStore[:routes] = {
        '/test-route' => { groups: {} },
      }

      allow(event).to receive(:duration).and_return(0.1)
    end

    context "and when the Airbrake config disables performance stats" do
      before do
        allow(Airbrake::Config.instance)
          .to receive(:performance_stats).and_return(false)
      end

      it "doesn't set http group value of that route" do
        subject.call([])
        expect(route[:groups][:http]).to be_nil
      end
    end

    context "and when the Airbrake config enables performance stats" do
      before do
        allow(Airbrake::Config.instance)
          .to receive(:performance_stats).and_return(true)
      end

      it "sets http group value of that route" do
        subject.call([])
        expect(route[:groups][:http]).to eq(0.1)
      end

      context "and when the subscriber is called multiple times" do
        before { expect(event).to receive(:duration).and_return(0.1) }

        it "increments http group value of that route" do
          subject.call([])
          subject.call([])

          expect(route[:groups][:http]).to eq(0.2)
        end
      end
    end
  end
end
