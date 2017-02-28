require 'spec_helper'
require 'airbrake/logger/logger_ext'

RSpec.describe Logger do
  let(:project_id) { 113743 }
  let(:project_key) { 'fd04e13d806a90f96614ad8e529b2822' }

  let(:endpoint) do
    "https://airbrake.io/api/v3/projects/#{project_id}/notices?key=#{project_key}"
  end

  let(:airbrake) do
    Airbrake::Notifier.new(project_id: project_id, project_key: project_key)
  end

  let(:logger) { Logger.new('/dev/null') }

  def wait_for_a_request_with_body(body)
    wait_for(a_request(:post, endpoint).with(body: body)).to have_been_made.once
  end

  before do
    stub_request(:post, endpoint).to_return(status: 201, body: '{}')
  end

  describe "#airbrake_notifier" do
    it "does not have a notifier specified by default" do
      expect(logger.airbrake_notifier).to be_nil
    end

    it "installs Airbrake notifier" do
      notifier_id = airbrake.object_id
      expect(logger.airbrake_notifier.object_id).not_to eq(notifier_id)

      logger.airbrake_notifier = airbrake
      expect(logger.airbrake_notifier.object_id).to eq(notifier_id)
    end

    context "when Airbrake is installed explicitly" do
      let(:out) { StringIO.new }
      let(:logger) { Logger.new(out) }

      before do
        logger.airbrake_notifier = airbrake
      end

      it "both logs and notifies using the specified notifier" do
        msg = 'bingo'
        logger.fatal(msg)

        wait_for_a_request_with_body(/"message":"#{msg}"/)
        expect(out.string).to match(/FATAL -- : #{msg}/)
      end

      it "sets the correct severity" do
        logger.fatal('bango')
        wait_for_a_request_with_body(/"context":{.*"severity":"critical".*}/)
      end

      it "sets the correct component" do
        logger.fatal('bingo')
        wait_for_a_request_with_body(/"component":"log"/)
      end

      it "strips out internal logger frames" do
        logger.fatal('bongo')

        wait_for(
          a_request(:post, endpoint).
            with(body: %r{"file":".+/logger.rb"})
        ).not_to have_been_made
        wait_for(a_request(:post, endpoint)).to have_been_made.once
      end
    end

    context "when Airbrake is not installed explicitly" do
      it "both logs and notifies using the default notifier" do
        expect(Airbrake[:default]).to receive(:notify)

        out = StringIO.new
        l = Logger.new(out)
        l.airbrake_notifier = nil
        msg = 'bango'
        l.fatal(msg)

        expect(out.string).to match("FATAL -- : #{msg}")
      end
    end
  end

  describe "#airbrake_severity_level" do
    context "when not set" do
      it "defaults to nil" do
        expect(logger.airbrake_severity_level).to be_nil
      end
    end

    context "when set" do
      before do
        logger.airbrake_notifier = airbrake
        logger.airbrake_severity_level = Logger::FATAL
      end

      it "does not notify below the specified level" do
        logger.error('bingo')
        wait_for(a_request(:post, endpoint)).not_to have_been_made
      end

      it "notifies in the current or above level" do
        logger.fatal('bingo')
        wait_for(a_request(:post, endpoint)).to have_been_made
      end

      it "falls back to Logger::WARN when it is lower" do
        logger.airbrake_severity_level = Logger::DEBUG
        expect(logger.airbrake_severity_level).to eq(Logger::WARN)
      end
    end
  end
end
