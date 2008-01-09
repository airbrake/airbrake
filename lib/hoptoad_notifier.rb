# Plugin for applications to automatically post errors to Hoptoad.
module HoptoadNotifier

  class << self
    attr_accessor :url, :app_name

    def url= url
      @url = URI.parse(url)
    end

    def filter_params
      @filter_params ||= %w(password)
    end
  end

  module Catcher
    
    def rescue_action_in_public exception
      if is_a_404?(exception)
        render_not_found_page
      else
        render_error_page
        data = {
          'notice' => {
            'project_name'  => HoptoadNotifier.app_name,
            'error_message' => exception.message,
            'backtrace' => clean_backtrace(exception.backtrace),
            'request'   => {
              'params'     => clean_params(request.parameters.to_hash),
              'rails_root' => File.expand_path(RAILS_ROOT),
              'url'        => "#{request.protocol}#{request.host}#{request.request_uri}"
            },
            'session' => {
              'key' => session.instance_variable_get("@session_id"),
              'data' => session.instance_variable_get("@data")
            },
            'environment' => ENV.to_hash
          }
        }
        inform_hoptoad(data)
      end
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

    def inform_hoptoad data
      url = HoptoadNotifier.url
      Net::HTTP.start(url.host, url.port) do |http|
        headers = {
          'Content-type' => 'application/x-yaml',
          'Accept' => 'text/xml, application/xml'
        }
        response = http.post url.path, data.to_yaml, headers
        case response
        when Net::HTTPSuccess then
          logger.info "Hoptoad Success: #{response.class}"
        when Net::HTTPRedirection then
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
        ActionController::UnknownAction
      ].include?( exception )
    end
    
    def clean_backtrace backtrace
      backtrace.to_a.map do |line|
        line = line.to_s
        line.gsub!(/#{RAILS_ROOT}/, "[RAILS_ROOT]")
        Gem.path.each do |path|
          line.gsub!(/#{path}/, "[GEM_PATH]")
        end
        line.gsub!(/^\.\//, "")
        line
      end
    end
    
    def clean_params params
      params.each do |k, v|
        params[k] = "<filtered>" if HoptoadNotifier.filter_params.any? do |filter|
          k.to_s.match(/#{filter}/)
        end
      end
    end
      
  end
end