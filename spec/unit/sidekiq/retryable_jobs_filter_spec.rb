# frozen_string_literal: true

require 'sidekiq'
require 'sidekiq/cli'
require 'airbrake/sidekiq'

RSpec.describe Airbrake::Sidekiq::RetryableJobsFilter do
  subject(:filter) { described_class.new }

  def build_notice(job = nil)
    Airbrake::Notice.new(StandardError.new, job: job)
  end

  it "does not ignore notices that are not from jobs" do
    notice = build_notice
    filter.call(notice)
    expect(notice).to_not be_ignored
  end

  it "does not ignore notices from jobs that have retries disabled" do
    notice = build_notice('retry' => false)
    filter.call(notice)
    expect(notice).to_not be_ignored
  end

  it "ignore notices from jobs that will be retried" do
    notice = build_notice('retry' => true, 'retry_count' => 0)
    filter.call(notice)
    expect(notice).to be_ignored
  end

  it "does not ignore notices from jobs that will not be retried" do
    notice = build_notice('retry' => 5, 'retry_count' => 4)
    filter.call(notice)
    expect(notice).to_not be_ignored
  end

  it "does not error if retry_count is missing" do
    notice = build_notice('retry' => 3)
    expect { filter.call(notice) }.to_not raise_error
  end

  context 'with max_retries = 2 arg passed to initializer' do
    subject(:filter) { described_class.new(max_retries: 2) }

    it "ignores notices when retry_count is null" do
      notice = build_notice('retry' => 5)
      filter.call(notice)
      expect(notice).to be_ignored
    end

    it "ignores notices when retry_count is 0" do
      notice = build_notice('retry' => 5, 'retry_count' => 0)
      filter.call(notice)
      expect(notice).to be_ignored
    end

    it "does not ignore notices when retry_count is 1" do
      notice = build_notice('retry' => 5, 'retry_count' => 1)
      filter.call(notice)
      expect(notice).to_not be_ignored
    end

    context "when Sidekiq thread reused" do
      it "should not ignore a job with a higher than default retry limit" do
        # This first job uses the global default retry limit and should memoize @max_retries
        notice1 = build_notice('retry' => true, 'retry_count' => 0)
        filter.call(notice1)
        expect(notice1).to be_ignored

        # This second job has a retry limit configured higher than the global default
        notice2 = build_notice('retry' => 1000, 'retry_count' => 900)
        filter.call(notice2)
        expect(notice2).not_to be_ignored
      end
    end
  end

  context "when Sidekiq thread reused" do
    it "should ignore a job with a higher than default retry limit" do
      # This first job uses the global default retry limit and should memoize @max_retries
      notice1 = build_notice('retry' => true, 'retry_count' => 0)
      filter.call(notice1)
      expect(notice1).to be_ignored

      # This second job has a retry limit configured higher than the global default
      notice2 = build_notice('retry' => 1000, 'retry_count' => 900)
      filter.call(notice2)
      expect(notice2).to be_ignored
    end
  end
end
