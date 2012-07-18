require File.expand_path '../helper', __FILE__

class UserInformerTest < Test::Unit::TestCase
  should "modify output if there is an airbrake id" do
    main_app = lambda do |env|
      env['airbrake.error_id'] = 1
      [200, {}, ["<!-- AIRBRAKE ERROR -->"]]
    end
    informer_app = Airbrake::UserInformer.new(main_app)

    ShamRack.mount(informer_app, "example.com")

    response = Net::HTTP.get_response(URI.parse("http://example.com/"))
    assert_equal "Airbrake Error 1", response.body
    assert_equal 16, response["Content-Length"].to_i
  end

  should "not modify output if there is no airbrake id" do
    main_app = lambda do |env|
      [200, {}, ["<!-- AIRBRAKE ERROR -->"]]
    end
    informer_app = Airbrake::UserInformer.new(main_app)

    ShamRack.mount(informer_app, "example.com")

    response = Net::HTTP.get_response(URI.parse("http://example.com/"))
    assert_equal "<!-- AIRBRAKE ERROR -->", response.body
  end
end
