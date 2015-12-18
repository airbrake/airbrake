require 'spec_helper'
require 'integration/shared_examples/rack_examples'

RSpec.describe "Rack integration specs" do
  let(:app) { DummyApp }

  include_examples 'rack examples'

  describe "context payload" do
    it "includes version" do
      get '/crash'
      wait_for_a_request_with_body(
        /"context":{.*"version":"1.2.3 Rack\.version.+Rack\.release/
      )
    end
  end
end
