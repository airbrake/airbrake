require 'spec_helper'

RSpec.describe Airbrake::Rack::NoticeBuilder do
  def env_for(url, opts = {})
    Rack::MockRequest.env_for(url, opts)
  end

  describe "#build_notice" do
    it "doesn't overwrite the session key with nil" do
      notice_builder = described_class.new(env_for('/', 'rack.session' => nil))
      notice = notice_builder.build_notice(AirbrakeTestError.new)

      expect(notice[:session]).to eq({})
    end

    it "sets session if it is present" do
      session = { a: 1, b: 2 }
      notice_builder = described_class.new(env_for('/', 'rack.session' => session))
      notice = notice_builder.build_notice(AirbrakeTestError.new)

      expect(notice[:session]).to eq(session)
    end

    it "doesn't overwrite the params key with nil" do
      notice_builder = described_class.new(env_for('/'))
      notice = notice_builder.build_notice(AirbrakeTestError.new)

      expect(notice[:session]).to eq({})
    end

    it "sets form params if they're present" do
      params = { a: 1, b: 2 }
      input = StringIO.new

      notice_builder = described_class.new(
        'rack.request.form_hash' => params,
        'rack.request.form_input' => input,
        'rack.input' => input
      )
      notice = notice_builder.build_notice(AirbrakeTestError.new)

      expect(notice[:params]).to eq(params)
    end

    it "sets query string params if they're present" do
      notice_builder = described_class.new(env_for('/?bingo=bango&bongo=bish'))
      notice = notice_builder.build_notice(AirbrakeTestError.new)

      expect(notice[:params]).to eq('bingo' => 'bango', 'bongo' => 'bish')
    end

    it "adds CONTENT_TYPE, CONTENT_LENGTH and HTTP_* headers in the environment" do
      headers = {
        "HTTP_HOST" => "example.com",
        "CONTENT_TYPE" => "text/html",
        "CONTENT_LENGTH" => 100500
      }
      notice_builder = described_class.new(env_for('/', headers.dup))
      notice = notice_builder.build_notice(AirbrakeTestError.new)
      expect(notice[:environment][:headers]).to eq(headers)
    end

    it "skips headers that were not selected to be stored in the environment" do
      headers = {
        "HTTP_HOST" => "example.com",
        "CONTENT_TYPE" => "text/html",
        "CONTENT_LENGTH" => 100500
      }
      notice_builder = described_class.new(
        env_for('/', headers.merge("X-SOME-HEADER" => "value"))
      )
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
      notice_builder = described_class.new(env_for('/', headers))
      notice = notice_builder.build_notice(AirbrakeTestError.new)

      expect(notice[:environment]["SOME_KEY"]).to eq("SOME_VALUE")
    end

    context "when a custom builder is defined" do
      before do
        described_class.add_builder do |notice, request|
          notice[:params][:remoteIp] = request.env['REMOTE_IP']
        end
      end

      after do
        described_class.instance_variable_get(:@builders).pop
      end

      it "runs the builder against notices" do
        notice_builder = described_class.new(env_for('/', 'REMOTE_IP' => '127.0.0.1'))
        notice = notice_builder.build_notice(AirbrakeTestError.new)

        expect(notice[:params][:remoteIp]).to eq("127.0.0.1")
      end
    end

    context "when Airbrake is not configured" do
      it "returns nil" do
        allow(Airbrake).to receive(:build_notice).and_return(nil)
        notice_builder = described_class.new(env_for('/', 'bingo' => 'bango'))

        expect(notice_builder.build_notice('bongo')).to be_nil
        expect(Airbrake).to have_received(:build_notice)
      end
    end

    context "when a request has a body" do
      it "reads the body" do
        body = StringIO.new('<bingo>bongo</bango>')
        notice_builder = described_class.new(
          env_for('/', 'rack.input' => body)
        )
        notice = notice_builder.build_notice(AirbrakeTestError.new)

        expect(notice[:environment][:body]).to eq(body.string)
      end

      it "rewinds rack.input" do
        body = StringIO.new('<bingo>bongo</bango>' * 512)
        notice_builder = described_class.new(
          env_for('/', 'rack.input' => body)
        )

        notice_builder.build_notice(AirbrakeTestError.new)

        expect(body.pos).to be_zero
      end

      it "reads only first 512 bytes" do
        len = 513
        body = StringIO.new('a' * len)
        notice_builder = described_class.new(
          env_for('/', 'rack.input' => body)
        )
        notice = notice_builder.build_notice(AirbrakeTestError.new)

        expect(notice[:environment][:body]).to eq(body.string[0...len - 1])
      end
    end
  end
end
