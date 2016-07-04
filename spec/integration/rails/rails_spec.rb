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
      wait_for_a_request_with_body(/"context":{.*"version":"1.2.3 Rails/)
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

      context "when Airbrake is not configured" do
        it "doesn't report errors" do
          allow(Airbrake).to receive(:build_notice).and_return(nil)
          allow(Airbrake).to receive(:notify)

          get '/active_job'
          sleep 2

          wait_for(
            a_request(:post, endpoint).
            with(body: /"message":"active_job error"/)
          ).not_to have_been_made

          expect(Airbrake).to have_received(:build_notice)
          expect(Airbrake).not_to have_received(:notify)
        end
      end
    end
  end

  describe "Resque workers" do
    it "reports exceptions occurring in Resque workers" do
      with_resque { get '/resque' }

      wait_for_a_request_with_body(
        /"message":"resque\serror".*"params":{.*
         "class":"BingoWorker","args":\["bango","bongo"\].*}/x
      )
    end
  end

  # Delayed Job doesn't support Ruby 1.9.2
  if Gem::Version.new(RUBY_VERSION) > Gem::Version.new('1.9.2')
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
    end
  end

  describe "notice payload when a user is authenticated without Warden" do
    context "when the current_user method is defined" do
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
