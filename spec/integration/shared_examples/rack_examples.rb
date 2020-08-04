# frozen_string_literal: true

RSpec.shared_examples 'rack examples' do
  include Warden::Test::Helpers

  let(:endpoint) { 'https://api.airbrake.io/api/v3/projects/113743/notices' }

  before do
    stub_request(:post, endpoint).to_return(status: 200, body: '')
    allow(Airbrake::Config.instance)
      .to receive(:performance_stats).and_return(false)
  end

  after { Warden.test_reset! }

  describe "application routes" do
    describe "/index" do
      it "successfully returns 200 and body" do
        expect(Airbrake).not_to receive(:notify)

        get '/'

        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('Hello from index')
      end
    end

    describe "/crash" do
      it "returns 500 and sends a notice to Airbrake" do
        expect(Airbrake).to receive(:notify).with(
          an_instance_of(Airbrake::Notice),
        ) do |notice|
          expect(notice[:errors].first[:type]).to eq('AirbrakeTestError')
        end

        get '/crash'
      end
    end
  end

  describe "user payload" do
    let(:user) do
      OpenStruct.new(
        id: 1,
        email: 'qa@example.com',
        username: 'qa-dept',
        first_name: 'John',
        last_name: 'Doe',
      )
    end

    before { login_as(user) }

    it "reports user info" do
      get '/crash'
      sleep 2

      body = /
        "context":{.*
          "user":{
            "id":"1",
            "name":"John\sDoe",
            "username":"qa-dept",
            "email":"qa@example.com"}
      /x
      expect(a_request(:post, endpoint).with(body: body))
        .to have_been_made.at_least_once
    end
  end

  context "when additional parameters are present" do
    before do
      get '/crash', nil, 'HTTP_USER_AGENT' => 'Bot', 'HTTP_REFERER' => 'bingo.com'
      sleep 2
    end

    it "contains url" do
      body = %r("context":{.*"url":"http://example\.org/crash".*})
      expect(a_request(:post, endpoint).with(body: body))
        .to have_been_made.at_least_once
    end

    it "contains hostname" do
      body = /"context":{.*"hostname":".+".*}/
      expect(a_request(:post, endpoint).with(body: body))
        .to have_been_made.at_least_once
    end

    it "contains userAgent" do
      body = /"context":{.*"userAgent":"Bot".*}/
      expect(a_request(:post, endpoint).with(body: body))
        .to have_been_made.at_least_once
    end

    it "contains referer" do
      body = /"context":{.*"referer":"bingo.com".*}/
      expect(a_request(:post, endpoint).with(body: body))
        .to have_been_made.at_least_once
    end

    it "contains HTTP headers" do
      body = /"context":{.*"headers":{.*"CONTENT_LENGTH":"0".*}/
      expect(a_request(:post, endpoint).with(body: body))
        .to have_been_made.at_least_once
    end

    it "contains HTTP method" do
      body = /"context":{.*"httpMethod":"GET".*}/
      expect(a_request(:post, endpoint).with(body: body))
        .to have_been_made.at_least_once
    end
  end
end
