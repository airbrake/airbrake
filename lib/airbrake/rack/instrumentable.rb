# frozen_string_literal: true

module Airbrake
  module Rack
    # Instrumentable holds methods that simplify instrumenting Rack apps.
    # @example
    #   class UsersController
    #     extend Airbrake::Rack::Instrumentable
    #
    #     def index
    #       # ...
    #     end
    #     airbrake_capture_timing :index
    #   end
    #
    # @api public
    # @since v9.2.0
    module Instrumentable
      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/MethodLength
      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/PerceivedComplexity
      def airbrake_capture_timing(
        method_name, label: method_name.to_s,
        with: Airbrake::Config.instance.default_wrapping_style
      )
        args = Airbrake::HAS_ARGUMENT_FORWARDING ? '...' : '*args, &block'

        case with
        when :chain
          # NOTE: Don't use :chain with methods that have been prepended.
          # For use with methods that are already chained, or on platforms
          # where prepend doesn't work. Not compatible with operator methods.
          aliased = method_name.to_s.sub(/([?!=])$/, '')
          punctuation = Regexp.last_match(1)

          with_method = "#{aliased}_with_airbrake#{punctuation}"
          without_method = "#{aliased}_without_airbrake#{punctuation}"

          # Avoid stack overflows!
          if method_defined?(without_method) ||
             private_method_defined?(without_method)
            raise ArgumentError,
                  'airbrake_capture_timing called already for ' +
                  method_name.to_s
          end

          if punctuation == '='
            # There are syntax limitations with writer methods.
            if instance_method(method_name).arity == 1
              args = 'arg'
            elsif args == '...'
              args = '*args, **kw_args, &block'
            end
            call_without_method = "__send__('#{without_method}', #{args})"
          else
            # Normal method call.
            call_without_method = "#{without_method}(#{args})"
          end

          module_eval <<-RUBY, __FILE__, __LINE__ + 1
            def #{with_method}(#{args})
              Airbrake::Rack.capture_timing(#{label.to_s.inspect}) do
                #{call_without_method}
              end
            end
          RUBY

          alias_method without_method, method_name
          alias_method method_name, with_method

          if public_method_defined?(without_method)
            public method_name
          elsif protected_method_defined?(without_method)
            protected method_name
          elsif private_method_defined?(without_method)
            private method_name
          end

        when :prepend
          # NOTE: Don't use :prepend with MRI < 2.1.6 or 2.2.2, or platforms
          # that don't support prepend at all, or on methods that have been
          # extended with aliased methods as with alias_method_chain.
          # Supports regular or operator methods, already prepended or not.
          prepend(Module.new do
            module_eval <<-RUBY, __FILE__, __LINE__ + 1
              def #{method_name}(#{args})
                Airbrake::Rack.capture_timing(#{label.to_s.inspect}) do
                  super
                end
              end
            RUBY
          end)

        else
          raise ArgumentError, 'with: option supports :chain or :prepend'
        end
      end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/PerceivedComplexity
    end
  end
end
