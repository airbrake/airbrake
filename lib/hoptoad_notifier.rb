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
    
    def default_notification_options
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
      sender = Sender.new
      case notice
      when Hash
        sender.inform_hoptoad( default_notification_options.merge(notice) )
      when Exception
        sender.inform_hoptoad( sender.exception_to_data(notice) )
      end
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
    
    def rescue_action_in_public exception
      if is_a_404?(exception)
        render_not_found_page
      else
        render_error_page
        inform_hoptoad(exception_to_data(exception))
      end
    end 
        
    private

    def inform_hoptoad notification
      notification[:backtrace] = clean_hoptoad_backtrace(notification[:backtrace])
      if notification[:request].is_a?(Hash) && notification[:request][:params].is_a?(Hash)
        notification[:request][:params] = clean_hoptoad_params(notification[:request][:params])
      end
      send_to_hoptoad(:notice => notification)
    end

    def exception_to_data exception
      {
        :project_name  => HoptoadNotifier.project_name,
        :error_message => "#{exception.class.name}: #{exception.message}",
        :backtrace     => exception.backtrace,
        :request       => {
          :params        => request.parameters.to_hash,
          :rails_root    => File.expand_path(RAILS_ROOT),
          :url           => "#{request.protocol}#{request.host}#{request.request_uri}"
        },
        :session       => {
          :key           => session.instance_variable_get("@session_id"),
          :data          => session.instance_variable_get("@data")
        },
        :environment   => ENV.to_hash
      }
    end

    def render_not_found_page
      respond_to do |wants|
        wants.html { render :file => "#{RAILS_ROOT}/public/404.html", :status => :not_found }
        wants.all  { render :nothing => true, :status => :not_found }
      end
    end

    def render_error_page
      respond_to do |wants|
        wants.html { render :file => "#{RAILS_ROOT}/public/500.html", :status => :internal_server_error }
        wants.all  { render :nothing => true, :status => :internal_server_error }
      end
     
    end

    def send_to_hoptoad data
      url = HoptoadNotifier.url
      Net::HTTP.start(url.host, url.port) do |http|
        headers = {
          'Content-type' => 'application/x-yaml',
          'Accept' => 'text/xml, application/xml'
        }
        # http.use_ssl = HoptoadNotifier.secure
        response = http.post(url.path, stringify_keys(data).to_yaml, headers)
        case response
        when Net::HTTPSuccess then
          logger.info "Hoptoad Success: #{response.class}"
        else
          logger.error "Hoptoad Failure: #{response.class}\n#{response.body if response.respond_to? :body}"
        end
      end
    end
    
    def is_a_404? exception
      [ 
        ActiveRecord::RecordNotFound,
        ActionController::UnknownController,
        ActionController::UnknownAction,
        ActionController::RoutingError,
        *HoptoadNotifier.exceptions_for_404
      ].include?( exception.class )
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
    
    def convert_symbol_keys_to_strings(input = {})
      input.inject({}) do |result, pair|
        result[pair.first.to_s] = pair.last
        result
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
    include HoptoadNotifier::Catcher
  end
end
