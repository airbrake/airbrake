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
      if bundler_manages_gems?
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

  def environment_path
    File.join(rails_root, 'config', 'environment.rb')
  end

  def rakefile_path
    File.join(rails_root, 'Rakefile')
  end

  def bundle_gem(gem_name, version = nil)
    File.open(gemfile_path, 'a') do |file|
      gem = "gem '#{gem_name}'"
      gem += ", '#{version}'" if version
      file.puts(gem)
    end
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
    if rails3?
      request_script = <<-SCRIPT
        require 'config/environment'

        env      = Rack::MockRequest.env_for(#{uri.inspect})
        response = RailsRoot::Application.call(env).last

        if response.is_a?(Array)
          puts response.join
        else
          puts response.body
        end
      SCRIPT
      File.open(File.join(rails_root, 'request.rb'), 'w') { |file| file.write(request_script) }
      @terminal.cd(rails_root)
      @terminal.run("ruby -rthread ./script/rails runner -e #{environment} request.rb")
    elsif rails_uses_rack?
      request_script = <<-SCRIPT
        require 'config/environment'

        env = Rack::MockRequest.env_for(#{uri.inspect})
        app = Rack::Lint.new(ActionController::Dispatcher.new)

        status, headers, body = app.call(env)

        response = ""
        if body.respond_to?(:to_str)
          response << body
        else
          body.each { |part| response << part }
        end

        puts response
      SCRIPT
      File.open(File.join(rails_root, 'request.rb'), 'w') { |file| file.write(request_script) }
      @terminal.cd(rails_root)
      @terminal.run("ruby -rthread ./script/runner -e #{environment} request.rb")
    else
      uri = URI.parse(uri)
      request_script = <<-SCRIPT
        require 'cgi'
        class CGIWrapper < CGI
          def initialize(*args)
            @env_table = {}
            @stdinput = $stdin
            super(*args)
          end
          attr_reader :env_table
        end
        $stdin = StringIO.new("")
        cgi = CGIWrapper.new
        cgi.env_table.update({
          'HTTPS'          => 'off',
          'REQUEST_METHOD' => "GET",
          'HTTP_HOST'      => #{[uri.host, uri.port].join(':').inspect},
          'SERVER_PORT'    => #{uri.port.inspect},
          'REQUEST_URI'    => #{uri.request_uri.inspect},
          'PATH_INFO'      => #{uri.path.inspect},
          'QUERY_STRING'   => #{uri.query.inspect}
        })
        require 'dispatcher' unless defined?(ActionController::Dispatcher)
        Dispatcher.dispatch(cgi)
      SCRIPT
      File.open(File.join(rails_root, 'request.rb'), 'w') { |file| file.write(request_script) }
      @terminal.cd(rails_root)
      @terminal.run("ruby -rthread ./script/runner -e #{environment} request.rb")
    end
  end
end

World(RailsHelpers)
