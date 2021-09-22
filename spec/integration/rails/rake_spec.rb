# frozen_string_literal: true

RSpec.describe "Rake integration" do
  let(:task) { Rake::Task['bingo:bango'] }

  before do
    Rails.application.load_tasks
    allow(Airbrake).to receive(:notify_sync)
  end

  after do
    expect { task.invoke }.to raise_error(AirbrakeTestError)

    # Rake ensures that each task is executed only once per session. For testing
    # purposes, we run the task multiple times.
    task.reenable
  end

  it "sends the exception to Airbrake" do
    expect(Airbrake).to receive(:notify_sync)
      .with(an_instance_of(Airbrake::Notice))
  end

  describe "contains the context payload, which" do
    it "includes correct component" do
      expect(Airbrake).to receive(:notify_sync)
        .with(a_notice_with(%i[context component], 'rake'))
    end

    it "includes correct action" do
      expect(Airbrake).to receive(:notify_sync)
        .with(a_notice_with(%i[context action], 'bingo:bango'))
    end
  end

  describe "contains the params payload, which" do
    it "includes a task name" do
      expect(Airbrake).to receive(:notify_sync)
        .with(a_notice_with(%i[params rake_task name], 'bingo:bango'))
    end

    it "includes a timestamp" do
      expected_notice = a_notice_with(
        %i[params rake_task timestamp], /20\d\d-\d\d-\d\d.+/
      )
      expect(Airbrake).to receive(:notify_sync).with(expected_notice)
    end

    it "includes investigation" do
      expected_notice = a_notice_with(
        %i[params rake_task investigation], /Investigating bingo:bango/
      )
      expect(Airbrake).to receive(:notify_sync).with(expected_notice)
    end

    it "includes full comment" do
      expect(Airbrake).to receive(:notify_sync)
        .with(a_notice_with(%i[params rake_task full_comment], 'Dummy description'))
    end

    it "includes arg names" do
      expect(Airbrake).to receive(:notify_sync)
        .with(a_notice_with(%i[params rake_task arg_names], [:dummy_arg]))
    end

    it "includes arg description" do
      expect(Airbrake).to receive(:notify_sync)
        .with(a_notice_with(%i[params rake_task arg_description], '[dummy_arg]'))
    end

    it "includes locations" do
      expect(Airbrake).to receive(:notify_sync) do |notice|
        expect(notice[:params][:rake_task][:locations])
          .to match(array_including(%r{spec/apps/rails/dummy_task.rake:\d+:in}))
      end
    end

    it "includes sources" do
      expect(Airbrake).to receive(:notify_sync)
        .with(a_notice_with(%i[params rake_task sources], ['environment']))
    end

    it "includes prerequisite tasks" do
      expect(Airbrake).to receive(:notify_sync) do |notice|
        expect(notice[:params][:rake_task][:prerequisite_tasks])
          .to match(array_including(hash_including(name: 'bingo:environment')))
      end
    end

    it "includes argv info" do
      expect(Airbrake).to receive(:notify_sync)
        .with(a_notice_with(%i[params argv], %r{spec/integration/rails/.+_spec.rb}))
    end

    it "includes execute args" do
      expect(Airbrake).to receive(:notify_sync) do |notice|
        expect(notice[:params][:execute_args])
          .to be_an_instance_of(Rake::TaskArguments)
      end
    end
  end
end
