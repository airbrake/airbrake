require 'ostruct'
require 'airbrake/rails/action_controller_route_subscriber'

RSpec.describe Airbrake::Rails::ActionControllerRouteSubscriber do
  describe "#call" do
    let(:app) { double(Airbrake::Rails::App) }
    let(:event) { double(Airbrake::Rails::Event) }

    let(:event_params) do
      [
        'start_processing.action_controller',
        Time.new,
        Time.new,
        '123',
        { method: 'HEAD', path: '/crash' }
      ]
    end

    before do
      allow(Airbrake::Rails::App).to receive(:new).and_return(app)
      allow(Airbrake::Rails::Event).to receive(:new).and_return(event)
    end

    context "when request store has the :routes key" do
      let(:routes) do
        [Airbrake::Rails::App::Route.new('/crash', 'DummyController', 'crash')]
      end

      before do
        allow(app).to receive(:routes).and_return(routes)
        allow(event).to receive(:params).and_return(params)
        allow(event).to receive(:method).and_return('HEAD')
        allow(event).to receive(:response_type).and_return(:html)

        Airbrake::Rack::RequestStore[:routes] = {}
      end

      after { Airbrake::Rack::RequestStore.clear }

      context "and when the route can be found" do
        let(:params) do
          OpenStruct.new(controller: 'DummyController', action: 'crash')
        end

        it "stores a route in the request store under :routes" do
          subject.call(event_params)
          expect(Airbrake::Rack::RequestStore[:routes])
            .to eq('/crash' => { method: 'HEAD', response_type: :html, groups: {} })
        end
      end

      context "and when the event controller can't be found" do
        let(:params) do
          OpenStruct.new(controller: 'BananaController', action: 'crash')
        end

        it "doesn't store any routes in the request store under :routes" do
          subject.call(event_params)
          expect(Airbrake::Rack::RequestStore[:routes]).to be_empty
        end
      end

      context "and when the event action can't be found" do
        let(:params) do
          OpenStruct.new(controller: 'DummyController', action: 'banana')
        end

        it "doesn't store any routes in the request store under :routes" do
          subject.call(event_params)
          expect(Airbrake::Rack::RequestStore[:routes]).to be_empty
        end
      end
    end

    context "when request store doesn't have the :routes key" do
      before { Airbrake::Rack::RequestStore.clear }

      it "doesn't store any routes in the request store" do
        subject.call(event_params)
        expect(Airbrake::Rack::RequestStore[:routes]).to be_nil
      end
    end
  end
end
