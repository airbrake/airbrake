RSpec.describe Airbrake::Rack::RouteFilter do
  context "when there's no request object available" do
    it "doesn't add context/route" do
      notice = Airbrake.build_notice('oops')
      subject.call(notice)
      expect(notice[:context][:route]).to be_nil
    end
  end
end
