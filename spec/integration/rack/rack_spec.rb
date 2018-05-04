require 'spec_helper'
require 'integration/shared_examples/rack_examples'

RSpec.describe "Rack integration specs" do
  let(:app) { DummyApp }

  include_examples 'rack examples'

  describe "context payload" do
    it "includes version" do
      get '/crash'
      wait_for_a_request_with_body(
        /"context":{.*"versions":{"rack_version":"\d\..+","rack_release":"\d\..+"}/
      )
    end
  end
end
