require 'spec_helper'
require 'airbrake/shoryuken/error_handler'

module Airbrake
  ##
  # Provides tests for the Shoryuken integration.
  module Shoryuken
    RSpec.describe ErrorHandler do
      let(:error) { AirbrakeTestError.new('shoryuken error') }
      let(:body) { { message: 'message' } }
      let(:notice) { double 'Notice' }

      context "when there's an error" do
        it 'notifies' do
          expect(Airbrake).to receive(:build_notice).with(error, body: body).
            and_return(notice)

          expect(Airbrake).to receive(:notify).with(notice)

          expect do
            subject.call(nil, nil, nil, body) { raise error }
          end.to raise_error(error)
        end

        context "and it's a batch" do
          let(:body) { [{ message1: 'message1' }, { message2: 'message2' }] }

          it 'notifies' do
            expect(Airbrake).to receive(:build_notice).with(error, batch: body).
              and_return(notice)

            expect(Airbrake).to receive(:notify).with(notice)

            expect do
              subject.call(nil, nil, nil, body) { raise error }
            end.to raise_error(error)
          end
        end
      end

      context "when there's no error" do
        it 'does not notify ' do
          expect(Airbrake).to_not receive(:build_notice)
          expect(Airbrake).to_not receive(:notify)

          expect do
            expect { |b| subject.call(nil, nil, nil, body, &b) }.to yield_control
          end.to_not raise_error
        end
      end
    end
  end
end
