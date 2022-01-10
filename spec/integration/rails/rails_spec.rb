# frozen_string_literal: true

require 'integration/shared_examples/rack_examples'

# TODO: remove this when WebMock is fixed.
#
# WebMock 3 overrides our integration so we cannot test benchmark HTTP
# integrations anymore. It incorrectly uses monkey-patching instead of
# prepending their code. We want to force prepend again in the tests to have
# higher precedence than WebMock.
def force_http_libs_prepend
  Net::HTTP.prepend(Airbrake::Rails::NetHttp)
  HTTPClient.prepend(Airbrake::Rails::HTTPClient)
  Typhoeus::Request.prepend(Airbrake::Rails::TyphoeusRequest)

  # Curl doesn't support JRuby.
  return unless defined?(Curl)

  Curl::Easy.prepend(Airbrake::Rails::CurlEasy)
  Curl::Multi.singleton_class.prepend(Airbrake::Rails::CurlMulti)
end

RSpec.describe "Rails integration specs" do
  include Warden::Test::Helpers

  let(:app) { Rails.application }
  let(:config) { Airbrake::Config.instance }

  let!(:endpoint) do
    stub_request(:post, 'https://api.airbrake.io/api/v3/projects/113743/notices')
      .to_return(status: 200, body: '')
  end

  before(:all) { force_http_libs_prepend }

  before do
    stub_request(:put, %r{https://api.airbrake.io/api/v5/projects/113743/.+})
      .to_return(status: 201, body: '{}')

    allow(Airbrake).to receive(:notify_request)
    allow(Airbrake).to receive(:notify_query)
    allow(Airbrake).to receive(:notify_performance_breakdown)
    allow(config).to receive(:performance_stats).and_return(false)
  end

  include_examples 'rack examples'

  if ::Rails.version.to_i >= 5
    it "inserts the Airbrake Rack middleware after DebugExceptions" do
      middlewares = Rails.configuration.middleware.middlewares.map(&:inspect)
      own_idx = middlewares.index('Airbrake::Rack::Middleware')

      expect(middlewares[own_idx - 1]).to eq('ActionDispatch::DebugExceptions')
    end
  else
    it "inserts the Airbrake Rack middleware after ConnectionManagement" do
      middlewares = Rails.configuration.middleware.middlewares.map(&:inspect)
      own_idx = middlewares.index('Airbrake::Rack::Middleware')

      expect(middlewares[own_idx - 1])
        .to eq('ActiveRecord::ConnectionAdapters::ConnectionManagement')
    end
  end

  shared_examples "context payload content" do |route|
    let(:user) do
      stub_const('User', Struct.new(:id, :email, :username))
      User.new(1, 'qa@example.com', 'qa-dept')
    end

    before do
      login_as(user)
      get(route, foo: :bar)
      sleep 2
    end

    it "includes component information" do
      body = /"context":{.*"component":"dummy".*}/
      expect(a_request(:post, endpoint).with(body: body)).to have_been_made
    end

    it "includes action information" do
      body =
        case route
        when '/crash'
          /"context":{.*"action":"crash".*}/
        when '/notify_airbrake_helper'
          /"context":{.*"action":"notify_airbrake_helper".*}/
        when '/notify_airbrake_sync_helper'
          /"context":{.*"action":"notify_airbrake_sync_helper".*}/
        else
          raise 'Unknown route'
        end
      expect(a_request(:post, endpoint).with(body: body)).to have_been_made
    end

    it "includes version" do
      body = /"context":{.*"versions":{"rails":"\d\./
      expect(a_request(:post, endpoint).with(body: body)).to have_been_made
    end

    it "includes session" do
      body = /"context":{.*"session":{.*"session_id":"\w+".*}/
      expect(a_request(:post, endpoint).with(body: body)).to have_been_made
    end

    it "includes params" do
      action = route[1..]
      body = /"context":{.*"params":{.*"controller":"dummy","action":"#{action}".*}/
      expect(a_request(:post, endpoint).with(body: body)).to have_been_made
    end

    it "includes route" do
      body = /"context":{.*"route":"#{route}\(\.:format\)".*}/
      expect(a_request(:post, endpoint).with(body: body)).to have_been_made
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

  describe(
    "Active Record callbacks",
    skip: Gem::Version.new(Rails.version) > Gem::Version.new('4.2'),
  ) do
    it "reports exceptions in after_commit callbacks" do
      expect(Airbrake).to receive(:notify).with(
        an_instance_of(AirbrakeTestError),
      ) do |exception|
        expect(exception.message).to eq('after_commit')
      end

      get '/active_record_after_commit'
    end

    it "reports exceptions in after_rollback callbacks" do
      expect(Airbrake).to receive(:notify).with(
        an_instance_of(AirbrakeTestError),
      ) do |exception|
        expect(exception.message).to eq('after_rollback')
      end

      get '/active_record_after_rollback'
    end
  end

  if Gem::Version.new(Rails.version) >= Gem::Version.new('4.2')
    describe "ActiveJob jobs" do
      it "reports exceptions occurring in ActiveJob workers" do
        expect(Airbrake).to receive(:notify)
          .with(an_instance_of(Airbrake::Notice)).at_least(:once)

        get '/active_job'
        sleep 2 # Wait for ActiveJob job exiting
      end

      context "when Airbrake is not configured" do
        before do
          # Make sure we don't call `build_notice` more than 1 time. Rack
          # integration will try to handle error 500 and we want to prevent
          # that: https://github.com/airbrake/airbrake/pull/583
          allow_any_instance_of(Airbrake::Rack::Middleware).to(
            receive(:notify_airbrake),
          )
        end

        it "doesn't report errors" do
          expect(Airbrake).to receive(:notify).with(
            an_instance_of(Airbrake::Notice),
          ) { |notice|
            # TODO: this doesn't actually fail but prints a failure. Figure
            # out how to test properly.
            expect(notice[:errors].first[:message]).to eq('active_job error')
          }.at_least(:once)

          get '/active_job'
          sleep 2
        end
      end
    end
  end

  describe "Resque workers" do
    it "reports exceptions occurring in Resque workers" do
      expect(Airbrake).to receive(:notify_sync).with(
        anything,
        hash_including(
          'class' => 'BingoWorker',
          'args' => %w[bango bongo],
        ),
      )
      with_resque { get '/resque' }
    end
  end

  describe "DelayedJob jobs" do
    it "reports exceptions occurring in DelayedJob jobs" do
      expect(Airbrake).to receive(:notify).with(
        anything,
        hash_including(
          'handler' => "--- !ruby/struct:BangoJob\nbingo: bingo\nbongo: bongo\n",
        ),
      )

      get '/delayed_job'
    end
  end

  describe "user extraction" do
    context "when Warden is not available but 'current_user' is defined" do
      let(:user) do
        stub_const('User', Struct.new(:id, :email, :username))
        User.new(1, 'qa@example.com', 'qa-dept')
      end

      before do
        allow_message_expectations_on_nil
        allow(Warden::Proxy).to receive(:new)
        # Mock on_request to make the test pass. Started failing in warden 1.2.8
        # due to: https://github.com/wardencommunity/warden/pull/162
        allow(nil).to receive(:on_request)
        allow_any_instance_of(DummyController).to receive(:current_user) { user }
      end

      it "sends user info" do
        get '/crash'
        sleep 2

        body = /"user":{"id":"1","username":"qa-dept","email":"qa@example.com"}/
        wait_for(a_request(:post, endpoint).with(body: body)).to have_been_made
      end
    end
  end

  describe "request performance hook" do
    before do
      allow(Airbrake).to receive(:notify)
      allow(config).to receive(:performance_stats).and_return(true)
    end

    it "notifies request" do
      expect(Airbrake).to receive(:notify_request).with(
        hash_including(
          route: '/crash(.:format)',
          method: 'GET',
        ),
      )
      get '/crash'
    end

    it "defaults to 500 when status code for exception returns 0" do
      allow(ActionDispatch::ExceptionWrapper)
        .to receive(:status_code).and_return(0)

      expect(Airbrake).to receive(:notify_request).with(
        hash_including(
          route: '/crash(.:format)',
          method: 'HEAD',
          status_code: 500,
        ),
      )
      head '/crash'
    end
  end

  describe "query performance hook" do
    before do
      allow(Airbrake).to receive(:notify)
      allow(config).to receive(:performance_stats).and_return(true)
    end

    it "sends queries to Airbrake" do
      expect(Airbrake).to receive(:notify_query).with(
        hash_including(
          route: '/crash(.:format)',
          method: 'GET',
          func: 'call',
          file: 'lib/airbrake/rails/active_record_subscriber.rb',
          line: anything,
        ),
      ).at_least(:once)

      get '/crash'
    end

    context "when caller location cannot be found for a query" do
      before { allow(Kernel).to receive(:caller).and_return([]) }

      it "sends query to Airbrake without caller location" do
        expect(Airbrake).to receive(:notify_query).with(
          hash_including(
            route: '/crash(.:format)',
            method: 'GET',
            func: nil,
            file: nil,
            line: nil,
          ),
        ).at_least(:once)

        get '/crash'
      end
    end
  end

  describe "performance breakdown hook" do
    before do
      allow(Airbrake).to receive(:notify)
      allow(config).to receive(:performance_stats).and_return(true)
    end

    it "sends performance breakdown info to Airbrake" do
      expect(Airbrake).to receive(:notify_performance_breakdown).with(
        hash_including(
          route: '/breakdown(.:format)',
          method: 'GET',
          response_type: :html,
          groups: hash_including(db: an_instance_of(Float)),
        ),
        an_instance_of(Hash),
      ).at_least(:once)

      get '/breakdown'
    end

    context "when response format is */*" do
      it "normalizes it to :html" do
        expect(Airbrake).to receive(:notify_performance_breakdown)
          .with(hash_including(response_type: :html), an_instance_of(Hash))
        get '/breakdown', {}, 'HTTP_ACCEPT' => '*/*'
      end
    end

    context "when db_runtime is nil" do
      it "omits the db group" do
        expect(Airbrake).to receive(:notify_performance_breakdown)
          .with(hash_including(groups: { view: be > 0 }), an_instance_of(Hash))
        get '/breakdown_view_only'
      end
    end

    context "when an action performs a Net::HTTP request" do
      let!(:example_request) do
        stub_request(:get, 'http://example.com').to_return(body: '')
      end

      before do
        if Airbrake::JRUBY
          skip("JRuby and WebMock don't work well with Net::HTTP monkey-patching")
        end
      end

      it "includes the http breakdown" do
        expect(Airbrake).to receive(:notify_performance_breakdown).with(
          hash_including(groups: { view: be > 0, http: be > 0 }),
          an_instance_of(Hash),
        )
        get '/breakdown_http'
        expect(example_request).to have_been_made
      end
    end

    context "when an action performs a Curl request" do
      let!(:example_request) do
        stub_request(:get, 'http://example.com').to_return(body: '')
      end

      before { skip("JRuby doesn't support Curb") if Airbrake::JRUBY }

      it "includes the http breakdown" do
        expect(Airbrake).to receive(:notify_performance_breakdown).with(
          hash_including(groups: { view: be > 0, http: be > 0 }),
          an_instance_of(Hash),
        )
        get '/breakdown_curl_http'
        expect(example_request).to have_been_made
      end
    end

    context "when an action performs a Curl::Easy request" do
      let!(:example_request) do
        stub_request(:get, 'http://example.com').to_return(body: '')
      end

      before { skip("JRuby doesn't support Curb") if Airbrake::JRUBY }

      it "includes the http breakdown" do
        expect(Airbrake).to receive(:notify_performance_breakdown).with(
          hash_including(groups: { view: be > 0, http: be > 0 }),
          an_instance_of(Hash),
        )
        get '/breakdown_curl_http_easy'
        expect(example_request).to have_been_made
      end
    end

    context "when an action performs a Curl::Multi request" do
      before { skip("JRuby doesn't support Curb") if Airbrake::JRUBY }

      it "includes the http breakdown" do
        expect(Airbrake).to receive(:notify_performance_breakdown).with(
          hash_including(groups: { view: be > 0, http: be > 0 }),
          an_instance_of(Hash),
        )
        get '/breakdown_curl_http_multi'
      end
    end

    context "when an action performs an Excon request" do
      let!(:example_request) do
        stub_request(:get, 'http://example.com').to_return(body: '')
      end

      it "includes the http breakdown" do
        expect(Airbrake).to receive(:notify_performance_breakdown).with(
          hash_including(groups: { view: be > 0, http: be > 0 }),
          an_instance_of(Hash),
        )
        get '/breakdown_excon'
        expect(example_request).to have_been_made
      end
    end

    context "when an action performs a HTTP.rb request" do
      let!(:example_request) do
        stub_request(:get, 'http://example.com').to_return(body: '')
      end

      it "includes the http breakdown" do
        expect(Airbrake).to receive(:notify_performance_breakdown).with(
          hash_including(groups: { view: be > 0, http: be > 0 }),
          an_instance_of(Hash),
        )
        get '/breakdown_http_rb'
        expect(example_request).to have_been_made
      end
    end

    context "when an action performs a HTTPClient request" do
      let!(:example_request) do
        stub_request(:get, 'http://example.com').to_return(body: '')
      end

      before do
        if Airbrake::JRUBY
          skip("JRuby and WebMock don't work well with Net::HTTP monkey-patching")
        end
      end

      it "includes the http breakdown" do
        expect(Airbrake).to receive(:notify_performance_breakdown).with(
          hash_including(groups: { view: be > 0, http: be > 0 }),
          an_instance_of(Hash),
        )
        get '/breakdown_http_client'
        expect(example_request).to have_been_made
      end
    end

    context "when an action performs a Typhoeus request" do
      let!(:example_request) do
        stub_request(:get, 'http://example.com').to_return(body: '')
      end

      before do
        # On JRuby 9.2.19.0 this fails with a SIGSEGV in JVM:
        # https://bit.ly/3Everoa
        # This is somehow related to libcurl.so.
        skip('SIGSEGV on JRuby 9.2.19.0') if Airbrake::JRUBY
      end

      it "includes the http breakdown" do
        expect(Airbrake).to receive(:notify_performance_breakdown).with(
          hash_including(groups: { view: be > 0, http: be > 0 }),
          an_instance_of(Hash),
        )
        get '/breakdown_typhoeus'
        expect(example_request).to have_been_made
      end
    end

    context "when current user is logged in" do
      let(:user) do
        stub_const('User', Struct.new(:id, :email, :username))
        User.new(1, 'qa@example.com', 'qa-dept')
      end

      before do
        login_as(user)
        sleep 2
      end

      it "includes current user into the performance breakdown stash" do
        expect(Airbrake).to receive(:notify_performance_breakdown).with(
          an_instance_of(Hash),
          hash_including(
            request: anything,
            user: { id: '1', username: 'qa-dept', email: 'qa@example.com' },
          ),
        )

        get '/breakdown'
      end
    end
  end
end
