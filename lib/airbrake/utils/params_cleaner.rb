module Airbrake
  module Utils
    class ParamsCleaner
      attr_writer :blacklist_filters, :whitelist_filters, :to_clean
      attr_reader :parameters, :cgi_data, :session_data

      # Public: Initialize a new Airbrake::Utils::ParamsCleaner
      #
      # opts - The Hash options that contain filters and params (default: {}):
      #        :blacklist_filters - The Array of param keys that should be filtered
      #        :whitelist_filters - The Array of param keys that shouldn't be filtered
      #        :to_clean - The Hash of unfiltered params
      #        :blacklist_filters take precedence over the :whitelist_filters
      def initialize(opts = {})
        @blacklist_filters = (opts[:blacklist_filters] || []).flatten
        @blacklist_filters.map!{|f| f.is_a?(Symbol) ? f.to_s : f }
        @whitelist_filters = (opts[:whitelist_filters] || []).flatten
        @whitelist_filters.map!{|f| f.is_a?(Symbol) ? f.to_s : f }
        @to_clean = opts[:to_clean]
      end

      # Public: Takes the params to_clean passed in an initializer
      #         and filters them out by filters passed.
      #
      #         Also normalizes unserializable data.
      #
      # Returns self, so that :parameters, :cgi_data, :session_data
      # could be extracted
      def clean
        clean_parameters
        clean_session_data
        clean_cgi_data
        clean_rack_request_data

        self
      end

      private

        def clean_parameters
          return unless @to_clean[:parameters]

          @parameters = if any_filters?
            filter(clean_unserializable_data(@to_clean[:parameters]))
          else
            clean_unserializable_data(@to_clean[:parameters])
          end
        end

        def clean_cgi_data
          return unless @to_clean[:cgi_data]

          @cgi_data = if any_filters?
            filter(clean_unserializable_data(@to_clean[:cgi_data]))
          else
            clean_unserializable_data(@to_clean[:cgi_data])
          end
        end

        def clean_session_data
          return unless @to_clean[:session_data]

          @session_data = if any_filters?
            filter(clean_unserializable_data(@to_clean[:session_data]))
          else
            clean_unserializable_data(@to_clean[:session_data])
          end
        end

        def clean_rack_request_data
          if @cgi_data
            @cgi_data.reject! do |key, val|
              Airbrake::FILTERED_RACK_VARS.include?(key) || Airbrake::SENSITIVE_ENV_VARS.any?{|re| re.match(key)}
            end
          end
        end

        def any_filters?
          @blacklist_filters.any? || @whitelist_filters.any?
        end

        def filter_key?(key)
          blacklist_key?(key) || !whitelist_key?(key)
        end

        def blacklist_key?(key)
          @blacklist_filters.any? do |filter|
            key == filter || filter.is_a?(Regexp) && filter.match(key)
          end
        end

        def whitelist_key?(key)
          return true if @whitelist_filters.empty?
          @whitelist_filters.any? do |filter|
            key == filter || filter.is_a?(Regexp) && filter.match(key)
          end
        end

        def filter(hash)
          hash.each do |key, value|
            if filter_key?(key)
              hash[key] = "[FILTERED]"
            elsif value.respond_to?(:to_hash)
              filter(hash[key])
            elsif value.is_a?(Array)
              hash[key] = value.inject(Array.new) do |result, item|
                item = filter(item) if item.is_a?(Enumerable)
                result.push(item)
              end
            end
          end
        end

        # Removes non-serializable data. Allowed data types are strings, arrays,
        # and hashes. All other types are converted to strings.
        def clean_unserializable_data(data, stack = [])
          return "[possible infinite recursion halted]" if stack.any?{|item| item == data.object_id }
          if data.is_a?(String)
            data
          elsif data.is_a?(Hash)
            data.inject({}) do |result, (key, value)|
              result.merge!(key => clean_unserializable_data(value, stack + [data.object_id]))
            end
          elsif data.respond_to?(:to_hash)
            data.to_hash.inject({}) do |result, (key, value)|
              result.merge!(key => clean_unserializable_data(value, stack + [data.object_id]))
            end
          elsif data.respond_to?(:collect) and !data.is_a?(IO)
            data = data.collect do |value|
              clean_unserializable_data(value, stack + [data.object_id])
            end
          elsif data.respond_to?(:to_ary)
            data = data.to_ary.collect do |value|
              clean_unserializable_data(value, stack + [data.object_id])
            end
          elsif data.respond_to?(:to_s)
            data.nil? ? nil : data.to_s
          end
        end
    end
  end
end
