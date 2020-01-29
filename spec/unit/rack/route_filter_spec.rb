# frozen_string_literal: true

RSpec.describe Airbrake::Rack::RouteFilter do
  context "when there's no request object available" do
    it "doesn't add context/route" do
      notice = Airbrake.build_notice('oops')
      subject.call(notice)
      expect(notice[:context][:route]).to be_nil
    end
  end

  context "when Sinatra route is unavailable" do
    before { stub_const('Sinatra::Request', Class.new) }

    let(:notice) do
      notice = Airbrake.build_notice('oops')

      request_mock = instance_double(Sinatra::Request)
      expect(request_mock)
        .to receive(:instance_of?).with(Sinatra::Request).and_return(true)
      expect(request_mock).to receive(:env).and_return({})

      notice.stash[:rack_request] = request_mock
      notice
    end

    it "doesn't add context/route" do
      subject.call(notice)
      expect(notice[:context][:route]).to be_nil
    end
  end

  context "when Sinatra route is available" do
    before { stub_const('Sinatra::Request', Class.new) }

    let(:notice) do
      notice = Airbrake.build_notice('oops')

      request_mock = instance_double(Sinatra::Request)
      expect(request_mock)
        .to receive(:instance_of?).with(Sinatra::Request).and_return(true)
      expect(request_mock)
        .to receive(:env).and_return('sinatra.route' => 'GET /test-route')

      notice.stash[:rack_request] = request_mock
      notice
    end

    it "doesn't add context/route" do
      subject.call(notice)
      expect(notice[:context][:route]).to eq('/test-route')
    end
  end
end
