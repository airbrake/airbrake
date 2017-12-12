require 'spec_helper'
require 'airbrake/shoryuken'

RSpec.describe Airbrake::Shoryuken::ErrorHandler do
  let(:error) { AirbrakeTestError.new('shoryuken error') }
  let(:body) { { message: 'message' } }
  let(:queue) { 'foo_queue' }

  let(:worker) do
    Class.new do
      def self.to_s
        'FooWorker'
      end
    end.new
  end

  let(:endpoint) { 'https://airbrake.io/api/v3/projects/113743/notices' }

  def wait_for_a_request_with_body(body)
    wait_for(a_request(:post, endpoint).with(body: body)).to have_been_made.once
  end

  before do
    stub_request(:post, endpoint).to_return(status: 201, body: '{}')
  end

  context "when there's an error" do
    it 'notifies' do
      expect do
        subject.call(worker, queue, nil, body) { raise error }
      end.to raise_error(error)

      wait_for_a_request_with_body(/"message":"shoryuken\serror"/)
      wait_for_a_request_with_body(/"params":{.*"queue":"#{queue}"/)
      wait_for_a_request_with_body(/"params":{.*"body":\{"message":"message"\}/)
      wait_for_a_request_with_body(/"component":"shoryuken","action":"FooWorker"/)
    end

    context "and it's a batch" do
      let(:body) { [{ message1: 'message1' }, { message2: 'message2' }] }

      it 'notifies' do
        expect do
          subject.call(worker, queue, nil, body) { raise error }
        end.to raise_error(error)

        wait_for_a_request_with_body(/"message":"shoryuken\serror"/)
        wait_for_a_request_with_body(/"params":{.*"queue":"#{queue}"/)
        wait_for_a_request_with_body(
          /"params":{.*"batch":\[\{"message1":"message1"\},\{"message2":"message2"\}\]/
        )
        wait_for_a_request_with_body(/"component":"shoryuken","action":"FooWorker"/)
      end
    end
  end

  context 'when Airbrake is not configured' do
    before do
      @notifiers = Airbrake.instance_variable_get(:@notifiers)
      @default_notifier = @notifiers.delete(:default)
    end

    after do
      @notifiers[:default] = @default_notifier
    end

    it "raises error" do
      expect do
        subject.call(worker, queue, nil, body) { raise error }
      end.to raise_error(error)
    end
  end
end
