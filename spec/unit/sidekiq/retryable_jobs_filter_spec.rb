if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('2.2.2')
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

    context 'with max_retries = 2' do
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
    end
  end
end
