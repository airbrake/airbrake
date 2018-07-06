require 'spec_helper'

if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('2.2.2')
  require 'sidekiq'
  require 'sidekiq/cli'
  require 'airbrake/sidekiq'

  RSpec.describe "airbrake/sidekiq/ignorable_error_class_filter" do
    subject(:filter) do
      Airbrake::Sidekiq::IgnorableErrorClassFilter.new(
        retry_attempts_before_airbrake: retry_attempts_before_airbrake,
        ignorable_classes: ignorable_classes
      )
    end

    let(:retry_attempts_before_airbrake) { 2 }
    let(:ignorable_classes) do
      ["OneIgnorableErrorClass"]
    end

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

    it "ignore notices from jobs that is an ignorable class" do
      notice = build_notice(
        'retry' => true,
        'retry_count' => 0,
        'error_class' => 'OneIgnorableErrorClass'
      )
      filter.call(notice)
      expect(notice).to be_ignored
    end

    it "does not ignore notices from ignorable class with higher retry count" do
      notice = build_notice(
        'retry' => true,
        'retry_count' => retry_attempts_before_airbrake + 1,
        'error_class' => 'OneIgnorableErrorClass'
      )
      filter.call(notice)
      expect(build_notice).to_not be_ignored
    end
  end
end
