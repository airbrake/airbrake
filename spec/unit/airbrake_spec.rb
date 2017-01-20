require 'spec_helper'

RSpec.describe Airbrake do
  let(:endpoint) do
    'https://airbrake.io/api/v3/projects/113743/notices?key=fd04e13d806a90f96614ad8e529b2822'
  end

  def env_for(url, opts = {})
    Rack::MockRequest.env_for(url, opts)
  end

  before do
    stub_request(:post, endpoint).to_return(status: 201, body: '{}')
  end

  describe ".add_rack_builder" do
    let(:filters) do
      notifier = Airbrake.instance_variable_get(:@notifiers)[:default]
      filter_chain = notifier.instance_variable_get(:@filter_chain)
      filter_chain.instance_variable_get(:@filters)
    end

    after { filters.pop }

    it "adds new builder to the filter chain" do
      expect do
        Airbrake.add_rack_builder(&proc { |_, _| nil })
      end.to change { filters.count }.by(1)
    end

    context "when notice has :rack_request in stash" do
      it "executes the filter yielding 2 params (last one is request)" do
        executed = false
        builder = proc do |notice, request|
          executed = true
          expect(notice).to be_an(Airbrake::Notice)
          expect(request).to be_a(Rack::Request)
        end
        Airbrake.add_rack_builder(&builder)

        notice = Airbrake.build_notice('oops')
        notice.stash[:rack_request] = Rack::Request.new(env_for('/'))
        Airbrake.notify_sync(notice)

        expect(executed).to be_truthy
      end
    end

    context "when notice doesn't have :rack_request in stash" do
      it "executes the filter yielding only one param" do
        executed = false
        builder = proc do |notice, request|
          executed = true
          expect(notice).to be_an(Airbrake::Notice)
          expect(request).to be_nil
        end
        Airbrake.add_rack_builder(&builder)

        Airbrake.notify_sync('oops')

        expect(executed).to be_truthy
      end
    end
  end
end
