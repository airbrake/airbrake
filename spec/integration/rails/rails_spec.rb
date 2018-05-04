require 'spec_helper'
require 'integration/shared_examples/rack_examples'

RSpec.describe "Rails integration specs" do
  include Warden::Test::Helpers

  let(:app) { Rails.application }

  include_examples 'rack examples'

  if ::Rails.version.start_with?('5.')
    it "inserts the Airbrake Rack middleware after DebugExceptions" do
      middlewares = Rails.configuration.middleware.middlewares.map(&:inspect)
      own_idx = middlewares.index('Airbrake::Rack::Middleware')

      expect(middlewares[own_idx - 1]).to eq('ActionDispatch::DebugExceptions')
    end
  else
    it "inserts the Airbrake Rack middleware after ConnectionManagement" do
      middlewares = Rails.configuration.middleware.middlewares.map(&:inspect)
      own_idx = middlewares.index('Airbrake::Rack::Middleware')

      expect(middlewares[own_idx - 1]).
        to eq('ActiveRecord::ConnectionAdapters::ConnectionManagement')
    end
  end

  shared_examples 'context payload content' do |route|
    before do
      login_as(OpenStruct.new(id: 1, email: 'qa@example.com', username: 'qa-dept'))
      get(route, foo: :bar)
    end

    it "includes component information" do
      wait_for_a_request_with_body(/"context":{.*"component":"dummy".*}/)
    end

    it "includes action information" do
      case route
      when '/crash'
        wait_for_a_request_with_body(/"context":{.*"action":"crash".*}/)
      when '/notify_airbrake_helper'
        wait_for_a_request_with_body(
          /"context":{.*"action":"notify_airbrake_helper".*}/
        )
      when '/notify_airbrake_sync_helper'
        wait_for_a_request_with_body(
          /"context":{.*"action":"notify_airbrake_sync_helper".*}/
        )
      else
        raise 'Unknown route'
      end
    end

    it "includes version" do
      wait_for_a_request_with_body(/"context":{.*"versions":{"rails":"\d\./)
    end

    it "includes session" do
      wait_for_a_request_with_body(
        /"context":{.*"session":{.*"session_id":"\w+".*}/
      )
    end

    it "includes params" do
      action = route[1..-1]
      wait_for_a_request_with_body(
        /"context":{.*"params":{.*"controller":"dummy","action":"#{action}".*}/
      )
    end
  end

  describe "context payload" do
    context "when exception reported through middleware" do
      include_examples('context payload content', '/crash')
    end

    context "when exception reported through the notify_airbrake helper" do
      include_examples('context payload content', '/notify_airbrake_helper')
    end

    context "when exception reported through the notify_airbrake_sync helper" do
      include_examples('context payload content', '/notify_airbrake_sync_helper')
    end
  end

  describe "Active Record callbacks" do
    if Gem::Version.new(Rails.version) >= Gem::Version.new('5.1.0.alpha')
      it "reports exceptions in after_commit callbacks" do
        get '/active_record_after_commit'
        sleep 2

        wait_for(
          a_request(:post, endpoint).
          with(body: /"type":"AirbrakeTestError","message":"after_commit"/)
        ).to have_been_made.twice
      end

      it "reports exceptions in after_rollback callbacks" do
        get '/active_record_after_rollback'
        sleep 2

        wait_for(
          a_request(:post, endpoint).
          with(body: /"type":"AirbrakeTestError","message":"after_rollback"/)
        ).to have_been_made.twice
      end
    else
      it "reports exceptions in after_commit callbacks" do
        get '/active_record_after_commit'
        wait_for_a_request_with_body(
          /"type":"AirbrakeTestError","message":"after_commit"/
        )
      end

      it "reports exceptions in after_rollback callbacks" do
        get '/active_record_after_rollback'
        wait_for_a_request_with_body(
          /"type":"AirbrakeTestError","message":"after_rollback"/
        )
      end
    end
  end

  if Gem::Version.new(Rails.version) >= Gem::Version.new('4.2')
    describe "ActiveJob jobs" do
      it "reports exceptions occurring in ActiveJob workers" do
        get '/active_job'
        sleep 2

        wait_for(
          a_request(:post, endpoint).
          with(body: /"message":"active_job error"/)
        ).to have_been_made.at_least_once
      end

      it "does not raise SystemStackError" do
        get '/active_job'
        sleep 2

        wait_for(
          a_request(:post, endpoint).
          with(body: /"type":"SystemStackError"/)
        ).not_to have_been_made
      end

      context "when Airbrake is not configured" do
        before do
          # Make sure the Logger intergration doesn't get in the way.
          allow_any_instance_of(Logger).to receive(:airbrake_notifier).and_return(nil)
        end

        it "doesn't report errors" do
          allow(Airbrake).to receive(:notify)

          # Make sure we don't call `build_notice` more than 1 time. Rack
          # integration will try to handle error 500 and we want to prevent
          # that: https://github.com/airbrake/airbrake/pull/583
          allow_any_instance_of(Airbrake::Rack::Middleware).to(
            receive(:notify_airbrake).
            and_return(nil)
          )

          get '/active_job'
          sleep 2

          wait_for(
            a_request(:post, endpoint).
            with(body: /"message":"active_job error"/)
          ).not_to have_been_made
        end
      end
    end
  end

  describe "Resque workers" do
    context "when Airbrake is configured" do
      it "reports exceptions occurring in Resque workers" do
        with_resque { get '/resque' }

        wait_for_a_request_with_body(
          /"message":"resque\serror".*"params":{.*
         "class":"BingoWorker","args":\["bango","bongo"\].*}/x
        )
      end
    end

    context "when Airbrake is not configured" do
      before do
        @notifiers = Airbrake.instance_variable_get(:@notifiers)
        @default_notifier = @notifiers.delete(:default)
      end

      after do
        @notifiers[:default] = @default_notifier
      end

      it "doesn't report errors" do
        with_resque { get '/resque' }

        wait_for(
          a_request(:post, endpoint).
            with(body: /"message":"resque error"/)
        ).not_to have_been_made
      end
    end
  end

  describe "DelayedJob jobs" do
    it "reports exceptions occurring in DelayedJob jobs" do
      get '/delayed_job'
      sleep 2

      wait_for_a_request_with_body(
        %r("message":"delayed_job\serror".*"params":{.*
           "handler":"---\s!ruby/struct:BangoJob\\nbingo:\s
                     bingo\\nbongo:\sbongo\\n".*})x
      )

      # Two requests are performed during this example. We care only about one.
      # Sleep guarantees that we let the unimportant request occur here and not
      # elsewhere.
      sleep 2
    end

    context "when Airbrake is not configured" do
      before do
        # Make sure the Logger intergration doesn't get in the way.
        allow_any_instance_of(Logger).to receive(:airbrake_notifier).and_return(nil)

        @notifiers = Airbrake.instance_variable_get(:@notifiers)
        @default_notifier = @notifiers.delete(:default)
      end

      after do
        @notifiers[:default] = @default_notifier
      end

      it "doesn't report errors" do
        # Make sure we don't call `build_notice` more than 1 time. Rack
        # integration will try to handle error 500 and we want to prevent
        # that: https://github.com/airbrake/airbrake/pull/583
        allow_any_instance_of(Airbrake::Rack::Middleware).to(
          receive(:notify_airbrake).
            and_return(nil)
        )

        get '/delayed_job'
        sleep 2

        wait_for(
          a_request(:post, endpoint).
            with(body: /"message":"delayed_job error"/)
        ).not_to have_been_made
      end
    end
  end

  describe "notice payload when a user is authenticated without Warden" do
    context "when the current_user method is defined" do
      before do
        allow(Warden::Proxy).to receive(:new) { nil }
      end

      it "contains the user information" do
        user = OpenStruct.new(id: 1, email: 'qa@example.com', username: 'qa-dept')
        allow_any_instance_of(DummyController).to receive(:current_user) { user }

        get '/crash'
        wait_for_a_request_with_body(
          /"user":{"id":"1","username":"qa-dept","email":"qa@example.com"}/
        )
      end
    end
  end
end
