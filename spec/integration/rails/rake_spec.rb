require 'spec_helper'

RSpec.describe "Rake integration" do
  let(:endpoint) { 'https://airbrake.io/api/v3/projects/113743/notices' }

  def wait_for_a_request_with_body(body)
    wait_for(a_request(:post, endpoint).with(body: body)).to have_been_made.once
  end

  def expect_no_requests_with_body(body)
    sleep 1
    expect(a_request(:post, endpoint).with(body: body)).not_to have_been_made
  end

  before do
    Rails.application.load_tasks
    stub_request(:post, endpoint).to_return(status: 201, body: '{}')
    expect { faulty_task.invoke }.to raise_error(AirbrakeTestError)
  end

  after do
    # Rake ensures that each task is executed only once per session. For testing
    # purposes, we run the task multiple times.
    faulty_task.reenable
  end

  describe "a task with maximum information, which raises an exception" do
    let(:faulty_task) { Rake::Task['bingo:bango'] }

    it "sends the exception to Airbrake" do
      wait_for_a_request_with_body(/"errors":\[{"type":"AirbrakeTestError"/)
    end

    describe "contains the context payload, which" do
      it "includes correct component" do
        wait_for_a_request_with_body(/"context":{.*"component":"rake".*}/)
      end

      it "includes correct action" do
        wait_for_a_request_with_body(
          /"context":{.*"action":"bingo:bango".*/
        )
      end
    end

    describe "contains the params payload, which" do
      it "includes a task name" do
        wait_for_a_request_with_body(
          /"params":{.*"rake_task":{.*"name":"bingo:bango".*}.*}/
        )
      end

      it "includes a timestamp" do
        wait_for_a_request_with_body(
          /"params":{.*"rake_task":{.*"timestamp":"201\d\-\d\d-\d\d.+".*}.*}/
        )
      end

      it "includes investigation" do
        # rubocop:disable Metrics/LineLength
        wait_for_a_request_with_body(
          /"params":{.*"rake_task":{.*"investigation":".+Investigating bingo:bango.+".*}.*}/
        )
        # rubocop:enable Metrics/LineLength
      end

      it "includes full comment" do
        wait_for_a_request_with_body(
          /"params":{.*"rake_task":{.*"full_comment":"Dummy description".*}.*}/
        )
      end

      it "includes arg names" do
        wait_for_a_request_with_body(
          /"params":{.*"rake_task":{.*"arg_names":\["dummy_arg"\].*}.*}/
        )
      end

      it "includes arg description" do
        wait_for_a_request_with_body(
          /"params":{.*"rake_task":{.*"arg_description":"\[dummy_arg\]".*}.*}/
        )
      end

      it "includes locations" do
        # rubocop:disable Metrics/LineLength
        wait_for_a_request_with_body(
          %r("params":{.*"rake_task":{.*"locations":\[".+spec/apps/rails/dummy_task.rake:\d+:in.+"\].*}.*})
        )
        # rubocop:enable Metrics/LineLength
      end

      it "includes sources" do
        wait_for_a_request_with_body(
          /"params":{.*"rake_task":{.*"sources":\["environment"\].*}.*}/
        )
      end

      it "includes prerequisite tasks" do
        # rubocop:disable Metrics/LineLength
        wait_for_a_request_with_body(
          /"params":{.*"rake_task":{.*"prerequisite_tasks":\[{"name":"bingo:environment".+\].*}.*}/
        )
        # rubocop:enable Metrics/LineLength
      end

      it "includes argv info" do
        wait_for_a_request_with_body(
          %r("params":{.*"argv":"--pattern spec/integration/rails/\*_spec.rb".*})
        )
      end

      it "includes #execute args" do
        wait_for_a_request_with_body(
          /"params":{.*"execute_args":\[\].*}/
        )
      end
    end
  end

  describe "a task with minimum information, which raises an exception" do
    let(:faulty_task) { Rake::Task['bingo:bongo'] }

    describe "doesn't contain in the params payload" do
      it "full comment" do
        expect_no_requests_with_body(
          /"params":{.*"rake_task":{.*"full_comment":"Dummy description".*}.*}/
        )
      end

      it "arg names" do
        expect_no_requests_with_body(
          /"params":{.*"rake_task":{.*"arg_names":\["dummy_arg"\].*}.*}/
        )
      end

      it "arg description" do
        expect_no_requests_with_body(
          /"params":{.*"rake_task":{.*"arg_description":"\[dummy_arg\]".*}.*}/
        )
      end

      it "sources" do
        expect_no_requests_with_body(
          /"params":{.*"rake_task":{.*"sources":\["environment"\].*}.*}/
        )
      end

      it "prerequisite tasks" do
        # rubocop:disable Metrics/LineLength
        expect_no_requests_with_body(
          /"params":{.*"rake_task":{.*"prerequisite_tasks":\[{"name":"bingo:environment".+\].*}.*}/
        )
        # rubocop:enable Metrics/LineLength
      end
    end
  end
end
