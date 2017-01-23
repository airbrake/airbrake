require 'spec_helper'

RSpec.describe Airbrake::Rack::ContextFilter do
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
  let(:opts) { Hash.new }

  it "adds framework version to the context" do
    subject.call(notice)
    expect(notice[:context][:version]).
      to match(/\d.\d.\d Rack\.version.+Rack\.release/)
  end

  context "when URL is present" do
    let(:uri) { '/bingo' }
    let(:opts) { Hash.new }

    it "adds URL to the context" do
      subject.call(notice)
      expect(notice[:context][:url]).to eq('http://example.org/bingo')
    end
  end

  context "when User-Agent is present" do
    let(:uri) { '/' }
    let(:opts) do
      { 'HTTP_USER_AGENT' => 'Bingo Agent' }
    end

    it "adds User-Agent to the context" do
      subject.call(notice)
      expect(notice[:context][:userAgent]).to eq('Bingo Agent')
    end
  end

  context "when controller is present" do
    let(:controller) do
      double.tap do |ctrl|
        allow(ctrl).to receive(:controller_name).and_return('BingoController')
        allow(ctrl).to receive(:action_name).and_return('bango_name')
      end
    end

    let(:uri) { '/' }
    let(:opts) do
      { 'action_controller.instance' => controller }
    end

    it "adds controller name as component" do
      subject.call(notice)
      expect(notice[:context][:component]).to eq('BingoController')
    end

    it "adds action name as action" do
      subject.call(notice)
      expect(notice[:context][:action]).to eq('bango_name')
    end
  end
end
