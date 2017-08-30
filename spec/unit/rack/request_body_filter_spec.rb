require 'spec_helper'

RSpec.describe Airbrake::Rack::RequestBodyFilter do
  def env_for(url, opts = {})
    Rack::MockRequest.env_for(url, opts)
  end

  subject { described_class.new }

  let(:notice) do
    Airbrake.build_notice('oops').tap do |notice|
      notice.stash[:rack_request] = Rack::Request.new(env_for(uri, opts))
    end
  end

  let(:uri) { '/' }
  let(:opts) do
    { 'rack.input' => body }
  end

  context "when a request has a body" do
    let(:body) { StringIO.new('<bingo>bongo</bango>') }

    it "reads the body" do
      subject.call(notice)
      expect(notice[:environment][:body]).to eq(body.string)
    end
  end

  context "when body was read" do
    let(:body) { StringIO.new('<bingo>bongo</bango>' * 512) }

    it "rewinds rack.input" do
      subject.call(notice)
      expect(body.pos).to be_zero
    end
  end

  context "when body is bigger than the limit" do
    let(:len) { 4097 }
    let(:body) { StringIO.new('a' * len) }

    it "reads only first 4096 bytes" do
      subject.call(notice)
      expect(notice[:environment][:body]).to eq(body.string[0...len - 1])
    end
  end
end
