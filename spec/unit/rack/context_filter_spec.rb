RSpec.describe Airbrake::Rack::ContextFilter do
  def env_for(url, opts = {})
    Rack::MockRequest.env_for(url, opts)
  end

  let(:request) { Rack::Request.new(env_for(uri, opts)) }

  let(:notice) do
    Airbrake.build_notice('oops').tap do |notice|
      notice.stash[:rack_request] = request
    end
  end

  let(:uri) { '/' }
  let(:opts) { {} }

  it "adds framework version to the context" do
    subject.call(notice)
    expect(notice[:context][:versions]).to include(
      'rack_version' => a_string_matching(/\d.\d/),
      'rack_release' => a_string_matching(/\d.\d\.\d/),
    )
  end

  context "when URL is present" do
    let(:uri) { '/bingo' }
    let(:opts) { {} }

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

  context "when visitor address is present" do
    let(:opts) do
      { 'REMOTE_ADDR' => '1.2.3.4' }
    end

    it "adds userAddr to the context" do
      subject.call(notice)
      expect(notice[:context][:userAddr]).to eq('1.2.3.4')
    end
  end

  context "when visitor is behind a proxy or load balancer" do
    let(:opts) do
      { 'HTTP_X_FORWARDED_FOR' => '8.8.8.8, 9.9.9.9' }
    end

    context "and when request responds to #remote_ip" do
      before { allow(request).to receive(:remote_ip).and_return('8.8.8.8') }

      it "adds userAddr based on request.remote_ip to the context" do
        subject.call(notice)
        expect(notice[:context][:userAddr]).to eq('8.8.8.8')
      end
    end

    context "and when request DOESN'T respond to #remote_ip" do
      before do
        allow(request).to receive(:respond_to?).with(:remote_ip).and_return(nil)
      end

      it "adds userAddr based on request.ip to the context" do
        subject.call(notice)
        expect(notice[:context][:userAddr]).to eq('9.9.9.9')
      end
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
