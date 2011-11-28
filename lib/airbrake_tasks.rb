require 'net/http'
require 'uri'
require 'active_support'
require 'airbrake/security'

# Capistrano tasks for notifying Airbrake of deploys
module AirbrakeTasks

  # Alerts Airbrake of a deploy.
  #
  # @param [Hash] opts Data about the deploy that is set to Airbrake
  #
  # @option opts [String] :rails_env Environment of the deploy (production, staging)
  # @option opts [String] :scm_revision The given revision/sha that is being deployed
  # @option opts [String] :scm_repository Address of your repository to help with code lookups
  # @option opts [String] :local_username Who is deploying
  def self.deploy(opts = {})
    if Airbrake.configuration.api_key.blank?
      puts "I don't seem to be configured with an API key.  Please check your configuration."
      return false
    end

    if opts[:rails_env].blank?
      puts "I don't know to which Rails environment you are deploying (use the TO=production option)."
      return false
    end

    dry_run = opts.delete(:dry_run)
    params = {'api_key' => opts.delete(:api_key) ||
                             Airbrake.configuration.api_key}
    opts.each {|k,v| params["deploy[#{k}]"] = v }

    host = Airbrake.configuration.host || 'airbrake.io'
    port = Airbrake.configuration.port || (Airbrake.configuration.secure ? 443 : 80)

    proxy = Net::HTTP.Proxy(Airbrake.configuration.proxy_host,
                            Airbrake.configuration.proxy_port,
                            Airbrake.configuration.proxy_user,
                            Airbrake.configuration.proxy_pass)
    http = proxy.new(host, port)

    # Handle Security
    http.use_ssl = Airbrake.configuration.secure
    http.ca_file = Airbrake::Security.ca_bundle_path if Airbrake.configuration.secure

    post = Net::HTTP::Post.new("/deploys.txt")
    post.set_form_data(params)

    if dry_run
      puts http.inspect, params.inspect
      return true
    else
      response = http.request(post)

      puts response.body
      return Net::HTTPSuccess === response
    end
  end
end

