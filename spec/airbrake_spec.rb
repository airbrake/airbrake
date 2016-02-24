require 'spec_helper'

RSpec.describe Airbrake do
  describe ".add_rack_builder" do
    let :builder do
      proc { |_, _| nil }
    end

    after { Airbrake::Rack::NoticeBuilder.builders.delete(builder) }

    it "adds new builder to the chain" do
      expect { Airbrake.add_rack_builder(&builder) }.to change {
        Airbrake::Rack::NoticeBuilder.builders.count
      }.by(1)
    end
  end
end
