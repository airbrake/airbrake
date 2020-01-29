# frozen_string_literal: true

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

  let(:notices_endpoint) do
    'https://api.airbrake.io/api/v3/projects/113743/notices'
  end

  let(:queues_endpoint) do
    'https://api.airbrake.io/api/v5/projects/113743/queues-stats'
  end

  def wait_for_a_request_with_body(body)
    wait_for(a_request(:post, notices_endpoint).with(body: body))
      .to have_been_made.once
  end

  before do
    stub_request(:post, notices_endpoint).to_return(status: 201, body: '{}')
    stub_request(:put, queues_endpoint).to_return(status: 201, body: '{}')

    allow(Airbrake).to receive(:notify_queue)
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
          /"params":{.*"batch":\[\{"message1":"message1"\},\{"message2":"message2"\}\]/,
        )
        wait_for_a_request_with_body(/"component":"shoryuken","action":"FooWorker"/)
      end

      it "sends queue info with positive error count" do
        allow(Airbrake).to receive(:notify)

        expect(Airbrake).to receive(:notify_queue).with(
          queue: 'FooWorker',
          error_count: 1,
          timing: 0.01,
        )

        expect do
          subject.call(worker, queue, nil, body) { raise error }
        end.to raise_error(error)
      end
    end
  end

  context "when the worker finishes without an error" do
    before { allow(Airbrake).to receive(:notify) }

    it "sends a zero error count queue info with groups" do
      expect(Airbrake).to receive(:notify_queue).with(
        queue: 'FooWorker',
        error_count: 0,
        timing: an_instance_of(Float),
      )

      expect { subject.call(worker, queue, nil, body) {} }.not_to raise_error
    end
  end
end
