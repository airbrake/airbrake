require 'spec_helper'

RSpec.describe Airbrake::Rack::RequestStore do
  after { described_class.clear }

  describe "#store" do
    it "returns an empty Hash" do
      expect(subject.store).to be_a(Hash)
      expect(subject.store).to be_empty
    end
  end

  describe "#[]=" do
    it "writes a value under a key" do
      subject[:foo] = :bar
      expect(subject.store).to eq(foo: :bar)
    end
  end

  describe "#[]" do
    it "reads a value under a key" do
      subject[:foo] = :bar
      expect(subject[:foo]).to eq(:bar)
    end
  end

  describe "#clear" do
    before do
      subject[:foo] = 1
      subject[:bar] = 2
    end

    it "clears everything in the store" do
      subject.clear
      expect(subject.store).to be_empty
    end
  end
end
