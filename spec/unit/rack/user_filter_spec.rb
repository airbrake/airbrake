require 'spec_helper'

RSpec.describe Airbrake::Rack::UserFilter do
  def env_for(url, opts = {})
    Rack::MockRequest.env_for(url, opts)
  end

  let(:notice) do
    Airbrake.build_notice('oops').tap do |notice|
      notice.stash[:rack_request] = Rack::Request.new(env_for('/', {}))
    end
  end

  let(:user_payload) { { username: 'bingo' } }
  let(:user) { Airbrake::Rack::User.new(double(user_payload)) }

  it "delegates extraction of the current user information" do
    expect(Airbrake::Rack::User).to receive(:extract).and_return(user)
    subject.call(notice)
    expect(notice[:context][:user]).to eq(user_payload)
  end

  context "when no current user is found" do
    let(:user) { Airbrake::Rack::User.new(double) }

    it "does not include the user key in the payload" do
      expect(Airbrake::Rack::User).to receive(:extract).and_return(user)
      subject.call(notice)
      expect(notice[:context].keys).not_to include(:user)
    end
  end
end
