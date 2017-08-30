require 'spec_helper'

RSpec.describe Airbrake::Rack::SessionFilter do
  def env_for(url, opts = {})
    Rack::MockRequest.env_for(url, opts)
  end

  subject { described_class.new }

  let(:notice) do
    Airbrake.build_notice('oops').tap do |notice|
      notice.stash[:rack_request] = Rack::Request.new(env_for(uri, opts))
    end
  end

  context "when rack session is nil" do
    let(:uri) { '/' }

    let(:opts) do
      { 'rack.session' => nil }
    end

    it "doesn't overwrite the session key with nil" do
      expect(notice[:session]).to eq({})

      subject.call(notice)

      expect(notice[:session]).to eq({})
    end
  end

  context "when session is present" do
    let(:session) do
      { a: 1, b: 2 }
    end

    let(:uri) { '/' }

    let(:opts) do
      { 'rack.session' => session }
    end

    it "sets session if it is present" do
      subject.call(notice)
      expect(notice[:session]).to eq(session)
    end
  end
end
