RSpec.describe Airbrake::Rack::Instrumentable do
  after { Airbrake::Rack::RequestStore.clear }

  describe ".airbrake_capture_timing" do
    let(:routes) { Airbrake::Rack::RequestStore[:routes] }

    let(:klass) do
      Class.new do
        extend Airbrake::Rack::Instrumentable

        def method; end
        airbrake_capture_timing :method

        def foo; end

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

        def method_with!(val); end
        airbrake_capture_timing :method_with!

        def method_with?(val); end
        airbrake_capture_timing :method_with?

        attr_writer :method_with
        airbrake_capture_timing :method_with=

        def ==(other)
          super
        end
        airbrake_capture_timing :==

        def method_with_block
          yield(1)
        end
        airbrake_capture_timing :method_with_block

        def method_with_everything!(a, b = nil, *args, foo:, bar: nil)
          raise ArgumentError if !a || !b || !foo || !bar || args.empty?
          yield(1)
        end
        airbrake_capture_timing :method_with_everything!

        def writer_with_everything=(a, b = nil, *args, foo:, bar: nil)
          raise ArgumentError if !a || !b || !foo || !bar || args.empty?
          yield(1)
        end
        airbrake_capture_timing :writer_with_everything=

        prepend(
          Module.new do
            def prepended_method!(*args, **kw_args)
              super
            end

            def prepended_writer=(*args, **kw_args)
              super
            end

            protected

            def a_prepended_protected_method
              super
            end

            private

            def a_prepended_private_method
              super
            end
          end,
        )

        def prepended_method!(a, b = nil, *args, foo:, bar: nil)
          raise ArgumentError if !a || !b || !foo || !bar || args.empty?
          yield(1)
        end
        airbrake_capture_timing :prepended_method!

        def prepended_writer=(a, b = nil, *args, foo:, bar: nil)
          raise ArgumentError if !a || !b || !foo || !bar || args.empty?
          yield(1)
        end
        airbrake_capture_timing :prepended_writer=

        protected

        def a_protected_method; end
        airbrake_capture_timing :a_protected_method

        def a_prepended_protected_method; end
        airbrake_capture_timing :a_prepended_protected_method

        private

        def a_private_method; end
        airbrake_capture_timing :a_private_method

        def a_prepended_private_method; end
        airbrake_capture_timing :a_prepended_private_method
      end
    end

    if defined?(Warning) && Warning.respond_to?(:warn)
      # Make sure there are no Ruby 2.7+ warnings.
      before do
        expect(Warning).to_not receive(:warn).with(any_args)
      end
    end

    it "doesn't generate any methods with invalid names" do
      expect(klass.instance_methods + klass.private_instance_methods)
        .to all match(/\A(\w+[?!=]?|\W+)\z/)
    end

    it "doesn't change visibility of public methods" do
      expect(klass.public_instance_methods)
        .to include(:method_with!, :prepended_method!)
    end

    it "doesn't change visibility of protected methods" do
      expect(klass.protected_instance_methods)
        .to include(:a_protected_method, :a_prepended_protected_method)
    end

    it "doesn't change visibility of private methods" do
      expect(klass.private_instance_methods)
        .to include(:a_private_method, :a_prepended_private_method)
    end

    it "returns the method name so other methods can use it" do
      expect(klass.airbrake_capture_timing(:foo)).to be :foo
    end

    it "doesn't generate too many anonymous modules" do
      # We should have two anonymous modules, including the one defined above.
      expect(klass.ancestors.index(klass)).to eq 2
      mod = klass.__send__("__airbrake_capture_timing_module__")
      expect(klass.ancestors.index(mod)).to be < 2
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
            groups: {},
          },
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

      it "attaches timing for a method with !" do
        klass.new.method_with!(1)
        expect(groups).to match('method_with!' => be > 0)
      end

      it "attaches timing for a method with ?" do
        klass.new.method_with?(1)
        expect(groups).to match('method_with?' => be > 0)
      end

      it "attaches timing for a writer method" do
        klass.new.method_with = 1
        expect(groups).to match('method_with=' => be > 0)
      end

      it "attaches timing for an inherited method" do
        klass.airbrake_capture_timing :dup
        klass.new.dup
        expect(groups).to match('dup' => be > 0)
      end

      it "attaches timing for an operator method" do
        expect(klass.new == 1).to eq false
        expect(groups).to match('==' => be > 0)
      end

      it "attaches timing for a method with a block given" do
        expect(klass.new.method_with_block(&->(_) { 'Hi!' })).to eq 'Hi!'
        expect(groups).to match('method_with_block' => be > 0)
      end

      it "attaches timing for a method with all arg types" do
        klass.new.send('method_with_everything!', 1, 2, 3, foo: 4, bar: 5) {}
        expect(groups).to match('method_with_everything!' => be > 0)
      end

      it "attaches timing for a writer method with all arg types" do
        klass.new.send('writer_with_everything=', 1, 2, 3, foo: 4, bar: 5) {}
        expect(groups).to match('writer_with_everything=' => be > 0)
      end

      it "attaches timing for a prepended method with all arg types" do
        klass.new.prepended_method!(1, 2, 3, foo: 4, bar: 5, &->(_) { "Hi!" })
        expect(groups).to match('prepended_method!' => be > 0)
      end

      it "attaches timing for a prepended writer method with all arg types" do
        klass.new.send('prepended_writer=', 1, 2, 3, foo: 4, bar: 5) {}
        expect(groups).to match('prepended_writer=' => be > 0)
      end

      it "attaches all timings for multiple methods to the request store" do
        klass.new.method
        klass.new.method_with_arg(1)

        expect(groups).to match(
          'method' => be > 0,
          'method_with_arg' => be > 0,
        )
      end

      context "and when a custom label was provided" do
        let(:klass) do
          Class.new do
            extend Airbrake::Rack::Instrumentable

            def method; end
            airbrake_capture_timing :method, label: 'custom label'

            def bar; end
          end
        end

        it "attaches timing under the provided label" do
          klass.new.method
          expect(groups).to match('custom label' => be > 0)
        end

        it "returns the method name so other methods can use it" do
          expect(klass.airbrake_capture_timing(:bar, label: :foo)).to be :bar
        end
      end
    end
  end
end
