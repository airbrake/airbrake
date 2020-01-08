require 'airbrake/rails/active_record_subscriber'

RSpec.describe Airbrake::Rails::ActiveRecordSubscriber do
  after { Airbrake::Rack::RequestStore.clear }

  describe "#call" do
    let(:event) { double(Airbrake::Rails::Event) }

    before do
      allow(Airbrake::Rails::Event).to receive(:new).and_return(event)
    end

    context "when there are no routes in the request store" do
      it "doesn't notify requests" do
        expect(Airbrake).not_to receive(:notify_query)
        subject.call([])
      end
    end

    context "when there's a route in the request store" do
      before do
        Airbrake::Rack::RequestStore[:routes] = {
          '/test-route' => { method: 'GET', response_type: :html },
        }

        allow(event).to receive(:sql).and_return('SELECT * FROM bananas')
        allow(event).to receive(:time).and_return(Time.now)
        allow(event).to receive(:duration).and_return(1.234)
        allow(Airbrake::Rails::BacktraceCleaner).to receive(:clean).and_return(
          "/lib/pry/cli.rb:117:in `start'",
        )
      end

      it "sends query info to Airbrake" do
        expect(Airbrake).to receive(:notify_query).with(
          hash_including(
            method: 'GET',
            route: '/test-route',
            query: 'SELECT * FROM bananas',
            func: 'start',
            line: 117,
            file: '/lib/pry/cli.rb',
          ),
        )
        subject.call([])
      end

      context "and when backtrace couldn't be parsed" do
        before do
          allow(Airbrake::Rails::BacktraceCleaner)
            .to receive(:clean).and_return([])
        end

        it "sends empty func/file/line to Airbrake" do
          expect(Airbrake).to receive(:notify_query).with(
            hash_including(
              method: 'GET',
              route: '/test-route',
              query: 'SELECT * FROM bananas',
              func: nil,
              line: nil,
              file: nil,
            ),
          )
          subject.call([])
        end
      end
    end
  end
end
