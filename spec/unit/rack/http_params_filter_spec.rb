require 'spec_helper'

RSpec.describe Airbrake::Rack::HttpParamsFilter do
  def env_for(url, opts = {})
    Rack::MockRequest.env_for(url, opts)
  end

  subject { described_class.new }

  let(:notice) do
    Airbrake.build_notice('oops').tap do |notice|
      notice.stash[:rack_request] = Rack::Request.new(env_for(uri, opts))
    end
  end

  context "when rack params is nil" do
    let(:uri) { '/' }
    let(:opts) { Hash.new }

    it "doesn't overwrite the params key with nil" do
      subject.call(notice)
      expect(notice[:params]).to eq({})
    end
  end

  context "when form params are present" do
    let(:params) do
      { a: 1, b: 2 }
    end

    let(:input) { StringIO.new }
    let(:uri) { '/' }
    let(:opts) do
      {
        'rack.request.form_hash' => params,
        'rack.request.form_input' => input,
        'rack.input' => input
      }
    end

    it "sets the params hash" do
      subject.call(notice)
      expect(notice[:params]).to eq(params)
    end
  end

  context "when query string params are present" do
    let(:uri) { '/?bingo=bango&bongo=bish' }
    let(:opts) { Hash.new }

    it "sets the params hash" do
      subject.call(notice)
      expect(notice[:params]).to eq('bingo' => 'bango', 'bongo' => 'bish')
    end
  end
end
