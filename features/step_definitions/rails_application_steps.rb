When /^I generate a new Rails application$/ do
  @terminal.cd(TEMP_DIR)
  version_string = ENV['RAILS_VERSION'] ? "_#{ENV['RAILS_VERSION']}_" : ''
  @terminal.run("rails #{version_string} rails_root")
  if rails_root_exists?
    @terminal.echo("Generated a Rails #{rails_version} application")
  else
    raise "Unable to generate a Rails application:\n#{@terminal.output}"
  end
end

Given /^I have installed the "([^\"]*)" gem$/ do |gem_name|
  @terminal.install_gem(gem_name)
end

Given /^I have built and installed the "([^\"]*)" gem$/ do |gem_name|
  @terminal.build_and_install_gem(File.join(PROJECT_ROOT, "#{gem_name}.gemspec"))
end

When /^I configure my application to require the "([^\"]*)" gem$/ do |gem_name|
  if rails_manages_gems?
    run = "Rails::Initializer.run do |config|"
    insert = "  config.gem '#{gem_name}'"
    content = File.read(environment_path)
    if content.sub!(run, "#{run}\n#{insert}")
      File.open(environment_path, 'wb') { |file| file.write(content) }
    else
      raise "Couldn't find #{run.inspect} in #{environment_path}"
    end
  else
    File.open(environment_path, 'a') do |file|
      file.puts
      file.puts("require 'hoptoad_notifier'")
      file.puts("require 'hoptoad_notifier/rails'")
    end

    unless rails_finds_generators_in_gems?
      FileUtils.cp_r(File.join(PROJECT_ROOT, 'generators'), File.join(RAILS_ROOT, 'lib'))
    end
  end
end

When /^I run "([^\"]*)"$/ do |command|
  @terminal.cd(RAILS_ROOT)
  @terminal.run(command)
end

Then /^I should receive a Hoptoad notification$/ do
  Then %{I should see "[Hoptoad] Success: Net::HTTPOK"}
end

Then /^I should receive two Hoptoad notifications$/ do
  @terminal.output.scan(/\[Hoptoad\] Success: Net::HTTPOK/).size.should == 2
end

When /^I configure the Hoptoad shim$/ do
  shim_file = File.join(PROJECT_ROOT, 'features', 'support', 'hoptoad_shim.rb.template')
  if rails_supports_initializers?
    target = File.join(RAILS_ROOT, 'config', 'initializers', 'hoptoad_shim.rb')
    FileUtils.cp(shim_file, target)
  else
    File.open(environment_path, 'a') do |file|
      file.puts
      file.write IO.read(shim_file)
    end
  end
end

When /^I configure the notifier to use "([^\"]*)" as an API key$/ do |api_key|
  config_file = File.join(RAILS_ROOT, 'config', 'initializers', 'hoptoad.rb')
  if rails_manages_gems?
    requires = ''
  else
    requires = "require 'hoptoad_notifier'"
  end

  initializer_code = <<-EOF
    #{requires}
    HoptoadNotifier.configure do |config|
      config.api_key = #{api_key.inspect}
    end
  EOF

  if rails_supports_initializers?
    File.open(config_file, 'w') { |file| file.write(initializer_code) }
  else
    File.open(environment_path, 'a') do |file|
      file.puts
      file.puts initializer_code
    end
  end
end

Then /^I should see "([^\"]*)"$/ do |expected_text|
  unless @terminal.output.include?(expected_text)
    raise("Got terminal output:\n#{@terminal.output}\n\nExpected output:\n#{expected_text}")
  end
end

When /^I uninstall the "([^\"]*)" gem$/ do |gem_name|
  @terminal.uninstall_gem(gem_name)
end

When /^I unpack the "([^\"]*)" gem$/ do |gem_name|
  if rails_manages_gems?
    @terminal.cd(RAILS_ROOT)
    @terminal.run("rake gems:unpack GEM=#{gem_name}")
  else
    vendor_dir = File.join(RAILS_ROOT, 'vendor', 'gems')
    FileUtils.mkdir_p(vendor_dir)
    @terminal.cd(vendor_dir)
    @terminal.run("gem unpack #{gem_name}")
    gem_path =
      Dir.glob(File.join(RAILS_ROOT, 'vendor', 'gems', "#{gem_name}-*", 'lib')).first
    File.open(environment_path, 'a') do |file|
      file.puts
      file.puts("$: << #{gem_path.inspect}")
    end
  end
end

When /^I install the "([^\"]*)" plugin$/ do |plugin_name|
  FileUtils.mkdir_p("#{RAILS_ROOT}/vendor/plugins/#{plugin_name}")
end

When /^I define a response for "([^\"]*)":$/ do |controller_and_action, definition|
  controller_class_name, action = controller_and_action.split('#')
  controller_name = controller_class_name.underscore
  controller_file_name = File.join(RAILS_ROOT, 'app', 'controllers', "#{controller_name}.rb")
  File.open(controller_file_name, "w") do |file|
    file.puts "class #{controller_class_name} < ApplicationController"
    file.puts "def consider_all_requests_local; false; end"
    file.puts "def local_request?; false; end"
    file.puts "def #{action}"
    file.puts definition
    file.puts "end"
    file.puts "end"
  end
end

When /^I perform a request to "([^\"]*)"$/ do |uri|
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
  File.open(File.join(RAILS_ROOT, 'request.rb'), 'w') { |file| file.write(request_script) }
  @terminal.cd(RAILS_ROOT)
  @terminal.run("./script/runner -e production request.rb")
end

Then /^I should receive the following Hoptoad notification:$/ do |table|
  exceptions = @terminal.output.scan(%r{Recieved the following exception:\n([^\n]*)\n}m)
  exceptions.should_not be_empty

  xml = exceptions.last[0]
  doc = Nokogiri::XML.parse(xml)

  hash = table.transpose.hashes.first

  doc.should have_content('//error/message', hash['error message'])
  doc.should have_content('//error/class',   hash['error class'])
  doc.should have_content('//request/url',   hash['url'])

  doc.should have_content('//component', hash['component']) if hash['component']
  doc.should have_content('//action', hash['action']) if hash['action']

  if hash['session']
    session_key, session_value = hash['session'].split(': ')
    doc.should have_content('//request/session/var/@key', session_key)
    doc.should have_content('//request/session/var',      session_value)
  end

  if hash['parameters']
    param_key, param_value     = hash['parameters'].split(': ')
    doc.should have_content('//request/params/var/@key',  param_key)
    doc.should have_content('//request/params/var',       param_value)
  end
end

Then /^I should see the Rails version$/ do
  Then %{I should see "[Rails: #{rails_version}]"}
end

