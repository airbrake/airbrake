BUNDLE_ENV_VARS = %w(RUBYOPT BUNDLE_PATH BUNDLE_BIN_PATH BUNDLE_GEMFILE)
ORIGINAL_BUNDLE_VARS = Hash[ENV.select{ |key,value| BUNDLE_ENV_VARS.include?(key) }]

ENV['RAILS_ENV'] = 'test'

Before do
  ENV['BUNDLE_GEMFILE'] = File.join(Dir.pwd, ENV['BUNDLE_GEMFILE']) unless ENV['BUNDLE_GEMFILE'].start_with?(Dir.pwd)
  @framework_version = nil
end

After do |s|
  ORIGINAL_BUNDLE_VARS.each_pair do |key, value|
    ENV[key] = value
  end
  Cucumber.wants_to_quit = true if s.failed?
end

module RailsHelpers
  def rails_root_exists?
    File.exists?(environment_path)
  end

  def application_controller_filename
    controller_filename = File.join(rails_root, 'app', 'controllers', "application_controller.rb")
  end

  def rails3?
    rails_version =~ /^3/
  end

  def rails_root
    LOCAL_RAILS_ROOT
  end

  def rails_uses_rack?
    rails3? || rails_version =~ /^2\.3/
  end

  def rails_version
    @rails_version ||= begin
      if ENV["RAILS_VERSION"]
        ENV["RAILS_VERSION"]
      elsif bundler_manages_gems?
        rails_version = open(gemfile_path).read.match(/gem.*rails["'].*["'](.+)["']/)[1]
      else
        environment_file = File.join(rails_root, 'config', 'environment.rb')
        rails_version = `grep RAILS_GEM_VERSION #{environment_file}`.match(/[\d.]+/)[0]
      end
    end
  end

  def bundler_manages_gems?
    File.exists?(gemfile_path)
  end

  def gemfile_path
    gemfile = File.join(rails_root, 'Gemfile')
  end

  def rails_manages_gems?
    rails_version =~ /^2\.[123]/
  end

  def rails_supports_initializers?
    rails3? || rails_version =~ /^2\./
  end

  def rails_finds_generators_in_gems?
    rails3? || rails_version =~ /^2\./
  end

  def version_string
    ENV['RAILS_VERSION'] || `tail -n 1 SUPPORTED_RAILS_VERSIONS` # use latest version if ENV["RAILS_VERSION"] is undefined
  end

  def environment_path
    File.join(rails_root, 'config', 'environment.rb')
  end

  def rakefile_path
    File.join(rails_root, 'Rakefile')
  end

  def config_gem(gem_name, version = nil)
    run     = "Rails::Initializer.run do |config|"
    insert  = "  config.gem '#{gem_name}'"
    insert += ", :version => '#{version}'" if version
    content = File.read(environment_path)
    content = "require 'thread'\n#{content}"
    if content.sub!(run, "#{run}\n#{insert}")
      File.open(environment_path, 'wb') { |file| file.write(content) }
    else
      raise "Couldn't find #{run.inspect} in #{environment_path}"
    end
  end

  def config_gem_dependencies
    insert = <<-END
    if Gem::VERSION >= "1.3.6"
      module Rails
        class GemDependency
          def requirement
            r = super
            (r == Gem::Requirement.default) ? nil : r
          end
        end
      end
    end
    END
    run     = "Rails::Initializer.run do |config|"
    content = File.read(environment_path)
    if content.sub!(run, "#{insert}\n#{run}")
      File.open(environment_path, 'wb') { |file| file.write(content) }
    else
      raise "Couldn't find #{run.inspect} in #{environment_path}"
    end
  end

  def require_thread
    content = File.read(rakefile_path)
    content = "require 'thread'\n#{content}"
    File.open(rakefile_path, 'wb') { |file| file.write(content) }
  end

  def perform_request(uri, environment = 'production')
    request_script = <<-SCRIPT
require File.expand_path('../config/environment', __FILE__)

env      = Rack::MockRequest.env_for(#{uri.inspect})
response = RailsRoot::Application.call(env)

response = response.last if response.last.is_a?(ActionDispatch::Response)

if response.is_a?(Array)
  puts "Status: " + response.first.to_s
  puts "Headers: " + response.second.to_s
  if response.last.respond_to?(:each)
    # making it work even with Rack::BodyProxy
    body = ""
    response.last.each do |chunk|
      body << chunk
    end
    response.pop
    response << body
  end
  puts "Body: " + response.last.to_s
else
  puts response.body
end
    SCRIPT
    File.open(File.join(rails_root, 'request.rb'), 'w') { |file| file.write(request_script) }
  end

end

World(RailsHelpers)
