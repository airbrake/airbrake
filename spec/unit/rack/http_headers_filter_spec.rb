require 'spec_helper'

RSpec.describe Airbrake::Rack::HttpHeadersFilter do
  def env_for(url, opts = {})
    Rack::MockRequest.env_for(url, opts)
  end

  subject { described_class.new }

  let(:notice) do
    Airbrake.build_notice('oops').tap do |notice|
      notice.stash[:rack_request] = Rack::Request.new(env_for(uri, opts))
    end
  end

  let(:headers) do
    {
      'HTTP_HOST' => 'example.com',
      'CONTENT_TYPE' => 'text/html',
      'CONTENT_LENGTH' => 100500
    }
  end

  let(:uri) { '/' }
  let(:opts) { headers.dup }

  it "preserves data that already has been added to the context" do
    notice[:context]['SOME_KEY'] = 'SOME_VALUE'
    subject.call(notice)
    expect(notice[:context]['SOME_KEY']).to eq('SOME_VALUE')
  end

  context "when CONTENT_TYPE, CONTENT_LENGTH and HTTP_* headers are present" do
    it "adds them to the context hash" do
      subject.call(notice)
      expect(notice[:context][:headers]).to eq(headers)
    end
  end

  context "when unexpected headers are present" do
    let(:opts) { headers.dup.merge('X-SOME-HEADER' => 'value') }

    it "adds them to the context hash" do
      subject.call(notice)
      expect(notice[:context][:headers]).to eq(headers)
    end
  end
end
