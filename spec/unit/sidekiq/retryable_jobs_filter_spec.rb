require 'spec_helper'

if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('2.2.2')
  require 'sidekiq'
  require 'sidekiq/cli'
  require 'airbrake/sidekiq'

  RSpec.describe "airbrake/sidekiq/retryable_jobs_filter" do
    subject(:filter) { Airbrake::Sidekiq::RetryableJobsFilter.new }
    def build_notice(job = nil)
      Airbrake::Notice.new(Airbrake::Config.new, StandardError.new, job: job)
    end

    it "does not ignore notices that are not from jobs" do
      notice = build_notice
      filter.call(notice)
      expect(build_notice).to_not be_ignored
    end

    it "does not ignore notices from jobs that have retries disabled" do
      notice = build_notice('retry' => false)
      filter.call(notice)
      expect(build_notice).to_not be_ignored
    end

    it "ignore notices from jobs that will be retried" do
      notice = build_notice('retry' => true, 'retry_count' => 0)
      filter.call(notice)
      expect(notice).to be_ignored
    end

    it "does not ignore notices from jobs that will not be retried" do
      notice = build_notice('retry' => 5, 'retry_count' => 5)
      filter.call(notice)
      expect(build_notice).to_not be_ignored
    end
  end
end
