require 'spec_helper'

RSpec.describe Airbrake::Rack::User do
  let(:endpoint) do
    'https://airbrake.io/api/v3/projects/113743/notices?key=fd04e13d806a90f96614ad8e529b2822'
  end

  let(:user) do
    OpenStruct.new(
      id: 1,
      email: 'qa@example.com',
      username: 'qa-dept',
      first_name: 'Bingo',
      last_name: 'Bongo'
    )
  end

  def env_for(url, opts = {})
    Rack::MockRequest.env_for(url, opts)
  end

  before do
    stub_request(:post, endpoint).to_return(status: 201, body: '{}')
  end

  describe ".extract" do
    context "when the Warden authentication framework is present" do
      it "returns the wrapped user" do
        warden = instance_double('Warden::Proxy')
        allow(warden).to receive(:user) { user }

        retval = described_class.extract(env_for('/', 'warden' => warden))
        expect(retval).to be_a(described_class)
      end

      context "and the warden user is nil" do
        it "returns nil" do
          warden = instance_double('Warden::Proxy')
          allow(warden).to receive(:user) { nil }

          retval = described_class.extract(env_for('/', 'warden' => warden))
          expect(retval).to be_nil
        end
      end
    end

    context "when the user was not found" do
      it "returns nil" do
        retval = described_class.extract(env_for('/'))
        expect(retval).to be_nil
      end
    end

    context "when the current_user Rails controller method is defined" do
      context "and it is nil" do
        it "returns nil" do
          controller = instance_double('DummyController')
          env = env_for('/', 'action_controller.instance' => controller)
          allow(controller).to receive(:current_user) { nil }

          retval = described_class.extract(env)
          expect(retval).to be_nil
        end
      end

      context "and it is not nil" do
        it "returns the wrapped user" do
          controller = instance_double('DummyController')
          env = env_for('/', 'action_controller.instance' => controller)
          allow(controller).to receive(:current_user) { user }

          retval = described_class.extract(env)
          expect(retval).to be_a(described_class)
        end
      end
    end
  end

  describe "#as_json" do
    context "when Rack user contains all expect fields" do
      let(:user_data) { described_class.new(user).as_json[:user] }

      it "contains the 'id' key" do
        expect(user_data).to include(:id)
      end

      it "contains the 'name' key" do
        expect(user_data).to include(:name)
      end

      it "contains the 'username' key" do
        expect(user_data).to include(:username)
      end

      it "contains the 'email' key" do
        expect(user_data).to include(:email)
      end
    end

    context "when Rack user doesn't contain any of the expect fields" do
      let(:user_data) { described_class.new(OpenStruct.new).as_json }

      it "is empty" do
        expect(user_data).to be_empty
      end
    end
  end
end
