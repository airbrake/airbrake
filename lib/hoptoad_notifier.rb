require 'net/http'

# Plugin for applications to automatically post errors to Hoptoad.
module HoptoadNotifier

  class << self
    attr_accessor :host, :port, :secure, :project_name, :filter_params
    attr_reader   :backtrace_filters

    def exceptions_for_404
      @exceptions_for_404 ||= []
    end
    
    def filter_backtrace &block
      (@backtrace_filters ||= []) << block
    end

    def port
      @port || (secure ? 443 : 80)
    end

    def params_filters
      @params_filters ||= %w(password)
    end
    
    def configure
      yield self
    end
    
    def protocol
      secure ? "https" : "http"
    end
    
    def url
      URI.parse("#{protocol}://#{host}:#{port}/notices/")
    end
    
    def default_notice_options
      {
        :project_name  => HoptoadNotifier.project_name,
        :error_message => 'Notification',
        :backtrace     => caller,
        :request       => {},
        :session       => {},
        :environment   => ENV.to_hash
      }
    end
    
    def notify notice = {}
      Sender.new.inform_hoptoad( notice )
    end
  end

  filter_backtrace do |line|
    line.gsub(/#{RAILS_ROOT}/, "[RAILS_ROOT]")
  end

  filter_backtrace do |line|
    line.gsub(/^\.\//, "")
  end

  filter_backtrace do |line|
    Gem.path.inject(line) do |line, path|
      line.gsub(/#{path}/, "[GEM_ROOT]")
    end
  end

  module Catcher

    def self.included(base)
      return if base.instance_methods.include? 'rescue_action_in_public_without_hoptoad'
      base.alias_method_chain :rescue_action_in_public, :hoptoad
    end
    
    def rescue_action_in_public_with_hoptoad exception
      inform_hoptoad(exception)
      rescue_action_in_public_without_hoptoad(exception)
    end 
        
    def inform_hoptoad hash_or_exception
      notice = normalize_notice(hash_or_exception)
      clean_notice(notice)
      send_to_hoptoad(:notice => notice)
    end

    private

    def exception_to_data exception
      data = {
        :project_name  => HoptoadNotifier.project_name,
        :error_message => "#{exception.class.name}: #{exception.message}",
        :backtrace     => exception.backtrace,
        :environment   => ENV.to_hash
      }

      if self.respond_to? :request
        data[:request] = {
          :params      => request.parameters.to_hash,
          :rails_root  => File.expand_path(RAILS_ROOT),
          :url         => "#{request.protocol}#{request.host}#{request.request_uri}"
        }
        data[:environment].merge!(request.env.to_hash)
      end

      if self.respond_to? :session
        data[:session] = {
          :key         => session.instance_variable_get("@session_id"),
          :data        => session.instance_variable_get("@data")
        }
      end

      data
    end

    def normalize_notice(notice)
      case notice
      when Hash
        HoptoadNotifier.default_notice_options.merge(notice)
      when Exception
        exception_to_data(notice)
      end
    end

    def clean_notice(notice)
      notice[:backtrace] = clean_hoptoad_backtrace(notice[:backtrace])
      if notice[:request].is_a?(Hash) && notice[:request][:params].is_a?(Hash)
        notice[:request][:params] = clean_hoptoad_params(notice[:request][:params])
      end
    end

    def send_to_hoptoad data
      url = HoptoadNotifier.url
      Net::HTTP.start(url.host, url.port) do |http|
        headers = {
          'Content-type' => 'application/x-yaml',
          'Accept' => 'text/xml, application/xml'
        }
        http.read_timeout = 5 # seconds
        http.open_timeout = 2 # seconds
        # http.use_ssl = HoptoadNotifier.secure
        response = begin
                     http.post(url.path, stringify_keys(data).to_yaml, headers)
                   rescue TimeoutError => e
                     logger.error "Timeout while contacting the Hoptoad server."
                     nil
                   end
        case response
        when Net::HTTPSuccess then
          logger.info "Hoptoad Success: #{response.class}"
        else
          logger.error "Hoptoad Failure: #{response.class}\n#{response.body if response.respond_to? :body}"
        end
      end
    end
    
    def clean_hoptoad_backtrace backtrace
      backtrace.to_a.map do |line|
        HoptoadNotifier.backtrace_filters.inject(line) do |line, proc|
          proc.call(line)
        end
      end
    end
    
    def clean_hoptoad_params params
      params.each do |k, v|
        params[k] = "<filtered>" if HoptoadNotifier.params_filters.any? do |filter|
          k.to_s.match(/#{filter}/)
        end
      end
    end
    
    def stringify_keys(hash)
      hash.inject({}) do |h, pair|
        h[pair.first.to_s] = pair.last.is_a?(Hash) ? stringify_keys(pair.last) : pair.last
        h
      end
    end
      
  end

  class Sender
    def rescue_action_in_public(exception)
    end

    include HoptoadNotifier::Catcher
  end
end
