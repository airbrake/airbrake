require 'net/http'
require 'uri'
require 'active_support'

module HoptoadTasks
  def self.deploy_to(rails_env)
    if HoptoadNotifier.api_key.blank?
      puts "I don't seem to be configured with an API key.  Please check your configuration."
      return false
    end

    if rails_env.blank?
      puts "I don't know to which Rails environment you are deploying (use the TO=production option)."
      return false
    end

    url = URI.parse("http://#{HoptoadNotifier.host}/deploys")
    response = Net::HTTP.post_form(url, :api_key => HoptoadNotifier.api_key, "deploy[rails_env]" => rails_env)
    puts response.body
    return Net::HTTPSuccess === response
  end
end

