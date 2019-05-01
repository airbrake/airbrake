RSpec.describe Airbrake::Rack::Instrumentable do
  after { Airbrake::Rack::RequestStore.clear }

  describe ".airbrake_capture_timing" do
    let(:routes) { Airbrake::Rack::RequestStore[:routes] }

    let(:klass) do
      Class.new do
        extend Airbrake::Rack::Instrumentable

        def method; end
        airbrake_capture_timing :method

        def method_with_arg(a); end
        airbrake_capture_timing :method_with_arg

        def method_with_args(a, b); end
        airbrake_capture_timing :method_with_args

        def method_with_vla(*args); end
        airbrake_capture_timing :method_with_vla

        def method_with_args_and_vla(*args); end
        airbrake_capture_timing :method_with_args_and_vla

        def method_with_kwargs(foo:, bar:); end
        airbrake_capture_timing :method_with_kwargs
      end
    end

    context "when request store doesn't have any routes" do
      before { Airbrake::Rack::RequestStore.clear }

      it "doesn't store timing of the tracked method" do
        klass.new.method
        expect(Airbrake::Rack::RequestStore.store).to be_empty
      end
    end

    context "when request store has a route" do
      let(:groups) { routes['/about'][:groups] }

      before do
        Airbrake::Rack::RequestStore[:routes] = {
          '/about' => {
            method: 'GET',
            response_type: :html,
            groups: {}
          }
        }
      end

      it "attaches timing for a method without an argument" do
        klass.new.method
        expect(groups).to match('method' => be > 0)
      end

      it "attaches timing for a method with an argument" do
        klass.new.method_with_arg(1)
        expect(groups).to match('method_with_arg' => be > 0)
      end

      it "attaches timing for a variable-length argument method" do
        klass.new.method_with_vla(1, 2, 3)
        expect(groups).to match('method_with_vla' => be > 0)
      end

      it "attaches timing for a method with args and a variable-length array" do
        klass.new.method_with_args_and_vla(1, 2, 3)
        expect(groups).to match('method_with_args_and_vla' => be > 0)
      end

      it "attaches timing for a method with kwargs" do
        klass.new.method_with_kwargs(foo: 1, bar: 2)
        expect(groups).to match('method_with_kwargs' => be > 0)
      end

      it "attaches all timings for multiple methods to the request store" do
        klass.new.method
        klass.new.method_with_arg(1)

        expect(groups).to match(
          'method' => be > 0,
          'method_with_arg' => be > 0
        )
      end

      context "and when a custom label was provided" do
        let(:klass) do
          Class.new do
            extend Airbrake::Rack::Instrumentable

            def method; end
            airbrake_capture_timing :method, label: 'custom label'
          end
        end

        it "attaches timing under the provided label" do
          klass.new.method
          expect(groups).to match('custom label' => be > 0)
        end
      end
    end
  end
end
