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
      headers = { "HTTP_HOST" => "example.com", "CONTENT_TYPE" => "text/html", "CONTENT_LENGTH" => 100500 }
      notice_builder = described_class.new(headers.dup)
      notice = notice_builder.build_notice(AirbrakeTestError.new)
      expect(notice[:environment][:headers]).to eq(headers)
    end

    it "skips headers that were not selected to be stored in the environment" do
      headers = { "HTTP_HOST" => "example.com", "CONTENT_TYPE" => "text/html", "CONTENT_LENGTH" => 100500 }
      notice_builder = described_class.new(headers.merge("X-SOME-HEADER" => "value"))
      notice = notice_builder.build_notice(AirbrakeTestError.new)
      expect(notice[:environment][:headers]).to eq(headers)
    end
  end
end
