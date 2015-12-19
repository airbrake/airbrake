RSpec.shared_examples 'rack examples' do
  include Warden::Test::Helpers

  after { Warden.test_reset! }

  let(:endpoint) do
    'https://airbrake.io/api/v3/projects/113743/notices?key=fd04e13d806a90f96614ad8e529b2822'
  end

  def wait_for_a_request_with_body(body)
    wait_for(a_request(:post, endpoint).with(body: body)).to have_been_made.once
  end

  before do
    stub_request(:post, endpoint).to_return(status: 201, body: '{}')
  end

  describe "application routes" do
    describe "/index" do
      it "successfully returns 200 and body" do
        get '/'

        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('Hello from index')

        wait_for(a_request(:post, endpoint)).not_to have_been_made
      end
    end

    describe "/crash" do
      it "returns 500 and sends a notice to Airbrake" do
        get '/crash'

        expect(last_response.status).to eq(500)
        wait_for_a_request_with_body(/"errors":\[{"type":"AirbrakeTestError"/)
      end
    end
  end

  describe "context payload" do
    context "when the user is present" do
      let(:common_user_params) do
        { id: 1, email: 'qa@example.com', username: 'qa-dept' }
      end

      before do
        login_as(OpenStruct.new(user_params))
        get '/crash'
      end

      context "when the user has first and last names" do
        let(:user_params) do
          common_user_params.merge(first_name: 'Bingo', last_name: 'Bongo')
        end

        it "reports the user's first and last names" do
          wait_for_a_request_with_body(/
            "context":{.*
              "user":{
                "id":"1",
                "name":"Bingo\sBongo",
                "username":"qa-dept",
                "email":"qa@example.com"}
          /x)
        end
      end

      context "when the user has only name" do
        let(:user_params) do
          common_user_params.merge(name: 'Bingo')
        end

        it "reports the user's name" do
          wait_for_a_request_with_body(/
            "context":{.*
              "user":{
                "id":"1",
                "name":"Bingo",
                "username":"qa-dept",
                "email":"qa@example.com"}
          /x)
        end
      end
    end

    context "when additional parameters present" do
      before do
        get '/crash', nil, 'HTTP_USER_AGENT' => 'Bot'
      end

      it "features url" do
        wait_for_a_request_with_body(
          %r("context":{.*"url":"http://example\.org/crash".*})
        )
      end

      it "features hostname" do
        wait_for_a_request_with_body(/"context":{.*"hostname":".+".*}/)
      end

      it "features userAgent" do
        wait_for_a_request_with_body(/"context":{.*"userAgent":"Bot".*}/)
      end
    end
  end
end
