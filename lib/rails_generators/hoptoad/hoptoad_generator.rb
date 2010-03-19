require 'rails/generators'

class HoptoadGenerator < Rails::Generators::Base

  class_option :api_key, :aliases => "-k", :type => :string, :desc => "Your Hoptoad API key"

  def self.source_root
    @_hoptoad_source_root ||= File.expand_path("../../../../generators/hoptoad/templates", __FILE__)
  end

  def install
    ensure_api_key_was_configured
    generate_initializer
    test_hoptoad
  end

  private

  def ensure_api_key_was_configured
    if !options[:api_key] # && !api_key_configured?
      puts "Must pass --api-key or create config/initializers/hoptoad.rb"
      exit
    end
  end

  def api_key
    options[:api_key]
  end

  def generate_initializer
    # api_key = options[:api_key]
    template 'initializer.rb', 'config/initializers/hoptoad.rb'
  end

  # Justified by scenario:
  #
  # Scenario: Configure the notifier by hand
  #
  # def api_key_configured?
  #   File.exists?('config/initializers/hoptoad.rb') || system("grep HoptoadNotifier config/environment.rb")
  # end

  def test_hoptoad
    puts run("rake hoptoad:test --trace")
  end
end
