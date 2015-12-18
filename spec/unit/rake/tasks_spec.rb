require 'spec_helper'

RSpec.describe "airbrake/rake/tasks" do
  let(:endpoint) do
    'https://airbrake.io/api/v4/projects/113743/deploys?key=fd04e13d806a90f96614ad8e529b2822'
  end

  def wait_for_a_request_with_body(body)
    wait_for(a_request(:post, endpoint).with(body: body)).to have_been_made.once
  end

  before do
    stub_request(:post, endpoint).to_return(status: 201, body: '{}')
  end

  describe "airbrake:deploy" do
    let(:task) { Rake::Task['airbrake:deploy'] }

    after { task.reenable }

    shared_examples 'deploy payload' do |key, val|
      it "sends #{key}" do
        ENV[key.upcase] = val
        task.invoke

        wait_for_a_request_with_body(/{.*"#{key}":"#{val}".*}/)
        ENV[key.upcase] = nil
      end
    end

    [%w(environment production),
     %w(username john),
     %w(revision 123abcdef),
     %w(repository https://github.com/airbrake/airbrake'),
     %w(version v2.0)
    ].each do |(key, val)|
      include_examples 'deploy payload', key, val
    end
  end
end
