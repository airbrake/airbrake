require 'spec_helper'
require 'sneakers'
require 'airbrake/sneakers'

RSpec.describe Airbrake::Sneakers::ErrorReporter do
  let(:worker) do
    queue = instance_double('queue')
    allow(queue).to receive_messages(
      name: 'test-queue',
      opts: {},
      exchange: instance_double('exchange')
    )

    Class.new do
      include Sneakers::Worker
      from_queue 'defaults'

      def work(_)
        raise 'oops error'
      end
    end.new(queue)
  end

  let(:error) { StandardError.new('Something is wrong') }
  let(:endpoint) { 'https://airbrake.io/api/v3/projects/113743/notices' }

  def wait_for_a_request_with_body(body)
    wait_for(a_request(:post, endpoint).with(body: body)).to have_been_made.once
  end

  before do
    stub_request(:post, endpoint).to_return(status: 201, body: '{}')

    Sneakers.configure(daemonize: true, log: '/dev/null')
    Sneakers::Worker.configure_metrics
  end

  after { Sneakers.clear! }

  it "should send a notice" do
    handler = instance_double('handler')
    expect(handler).to receive(:error).once
    allow(worker.logger).to receive(:error)
    worker.do_work(nil, nil, "msg", handler)

    wait_for_a_request_with_body(/"message":"oops error"/)
    wait_for_a_request_with_body(/test-queue/)
    wait_for_a_request_with_body(/"component":"sneakers"/)
  end

  it "should support call without worker" do
    subject.call(error, message: 'my_glorious_messsage', delivery_info: {})
    wait_for_a_request_with_body(/"message":"Something is wrong"/)
    wait_for_a_request_with_body(/"params":{"message":"my_glorious_messsage"/)
    # worker class is nil so action is NilClass
    wait_for_a_request_with_body(/"action":"NilClass"/)
    wait_for_a_request_with_body(/"component":"sneakers"/)
  end

  it "should support call with worker" do
    subject.call(error, '', message: 'my_special_message', delivery_info: {})
    wait_for_a_request_with_body(/"message":"Something is wrong"/)
    wait_for_a_request_with_body(/"params":{"message":"my_special_message"/)
    # worker class is a String so action is String
    wait_for_a_request_with_body(/"action":"String"/)
    wait_for_a_request_with_body(/"component":"sneakers"/)
    wait_for_a_request_with_body(
      /"params":{"message":"my_special_message","delivery_info":{}}/
    )
  end

  described_class::IGNORED_KEYS.each do |key|
    context "when delivery_info/#{key} is present" do
      it "filters out #{key}" do
        subject.call(
          error, '', message: 'msg', delivery_info: { key => 'a', foo: 'b' }
        )
        wait_for_a_request_with_body(
          /"params":{"message":"msg","delivery_info":{"foo":"b"}}/
        )
      end
    end
  end
end
