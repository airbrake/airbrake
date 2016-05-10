require 'spec_helper'

RSpec.describe Airbrake::Rack::NoticeBuilder do
  describe "#build_notice" do
    it "doesn't overwrite session with nil" do
      notice_builder = described_class.new('rack.session' => nil)
      notice = notice_builder.build_notice(AirbrakeTestError.new)

      expect(notice[:session]).to eq({})
    end

    it "sets session if it is present" do
      session = { a: 1, b: 2 }
      notice_builder = described_class.new('rack.session' => session)
      notice = notice_builder.build_notice(AirbrakeTestError.new)

      expect(notice[:session]).to eq(session)
    end

    it "doesn't overwrite params with nil" do
      notice_builder = described_class.new('action_dispatch.request.parameters' => nil)
      notice = notice_builder.build_notice(AirbrakeTestError.new)

      expect(notice[:session]).to eq({})
    end

    it "sets params if they're present" do
      params = { a: 1, b: 2 }
      notice_builder = described_class.new('action_dispatch.request.parameters' => params)
      notice = notice_builder.build_notice(AirbrakeTestError.new)

      expect(notice[:params]).to eq(params)
    end

    it "adds CONTENT_TYPE, CONTENT_LENGTH and HTTP_* headers in the environment" do
      headers = {
        "HTTP_HOST" => "example.com",
        "CONTENT_TYPE" => "text/html",
        "CONTENT_LENGTH" => 100500
      }
      notice_builder = described_class.new(headers.dup)
      notice = notice_builder.build_notice(AirbrakeTestError.new)
      expect(notice[:environment][:headers]).to eq(headers)
    end

    it "skips headers that were not selected to be stored in the environment" do
      headers = {
        "HTTP_HOST" => "example.com",
        "CONTENT_TYPE" => "text/html",
        "CONTENT_LENGTH" => 100500
      }
      notice_builder = described_class.new(headers.merge("X-SOME-HEADER" => "value"))
      notice = notice_builder.build_notice(AirbrakeTestError.new)
      expect(notice[:environment][:headers]).to eq(headers)
    end

    it "preserves data that already has been added to the environment" do
      headers = {
        "HTTP_HOST" => "example.com",
        "CONTENT_TYPE" => "text/html",
        "CONTENT_LENGTH" => 100500
      }
      allow(Airbrake).to receive(:build_notice).and_wrap_original do |method, *args|
        notice = method.call(*args)
        notice[:environment]["SOME_KEY"] = "SOME_VALUE"
        notice
      end
      notice_builder = described_class.new(headers)
      notice = notice_builder.build_notice(AirbrakeTestError.new)
      expect(notice[:environment]["SOME_KEY"]).to eq("SOME_VALUE")
    end

    it "runs user defined builders against notices" do
      extended_class = described_class.dup
      extended_class.add_builder do |notice, request|
        notice[:params][:remoteIp] = request.env['REMOTE_IP']
      end
      notice_builder = extended_class.new('REMOTE_IP' => '127.0.0.1')
      notice = notice_builder.build_notice(AirbrakeTestError.new)
      expect(notice[:params][:remoteIp]).to eq("127.0.0.1")
    end

    context "when Airbrake is not configured" do
      it "returns nil" do
        allow(Airbrake).to receive(:build_notice).and_return(nil)
        notice_builder = described_class.new('bingo' => 'bango')

        expect(notice_builder.build_notice('bongo')).to be_nil
        expect(Airbrake).to have_received(:build_notice)
      end
    end
  end
end
