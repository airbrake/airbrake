module Airbrake
  module Utils
    class ParamsCleaner
      attr_writer :filters, :to_clean
      attr_reader :parameters, :cgi_data, :session_data

      # Public: Initialize a new Airbrake::Utils::ParamsCleaner
      #   
      # opts - The Hash options that contain filters and params (default: {}):
      #        :filters - The Array of param keys that should be filtered
      #        :to_clean - The Hash of unfiltered params
      def initialize(opts = {})
        @filters     = opts[:filters] || {}
        @to_clean    = opts[:to_clean]
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
          if params = @to_clean[:parameters]
            @parameters = clean_unserializable_data(params)
            @parameters = filter @parameters
          end
        end

        def clean_cgi_data
          if params = @to_clean[:cgi_data]
            @cgi_data = clean_unserializable_data params
            @cgi_data = filter @cgi_data
          end
        end

        def clean_session_data
          if params = @to_clean[:session_data]
            @session_data = clean_unserializable_data params
            @session_data = filter @session_data
          end
        end

        def clean_rack_request_data
          if @cgi_data
            @cgi_data.keys.each do |key|
              if filter_key?(key, Airbrake::FILTERED_RACK_VARS)
                @cgi_data.delete key
              end
            end
          end
        end

        def filter_key?(key, filters)
          filters.any? do |filter|
            case filter
            when Regexp
              filter.match(key)
            else
              key.to_s.eql?(filter.to_s)
            end
          end
        end

        def filter(hash)
          hash.each do |key, value|
            if filter_key?(key, @filters)
              hash[key] = "[FILTERED]"
            elsif value.respond_to?(:to_hash)
              filter(hash[key])
            end
          end
        end

        # Removes non-serializable data. Allowed data types are strings, arrays,
        # and hashes. All other types are converted to strings.
        def clean_unserializable_data(data, stack = [])
          return "[possible infinite recursion halted]" if stack.any?{|item| item == data.object_id }

          if data.respond_to?(:to_hash)
            data.to_hash.inject({}) do |result, (key, value)|
              result.merge(key => clean_unserializable_data(value, stack + [data.object_id]))
            end
          elsif data.respond_to?(:to_ary)
            data.to_ary.collect do |value|
              clean_unserializable_data(value, stack + [data.object_id])
            end
          else
            data.nil? ? nil : data.to_s
          end
        end
    end
  end
end
