require File.expand_path '../helper', __FILE__

class ResponseTest < Test::Unit::TestCase
  include DefinesConstants

  def response_body
    File.read File.expand_path('../support/response_shim.xml', __FILE__)
  end

  should "output a nicely formatted notice details" do
    output = Airbrake::Response.pretty_format(response_body)

    assert %r{ID: b6817316-9c45-ed26-45eb-780dbb86aadb}, "#{output}"
    assert %r{URL: http://airbrake.io/locate/b6817316-9c45-ed26-45eb-780dbb86aadb},
      "#{output}"

  end
end
