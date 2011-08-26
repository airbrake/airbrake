require 'uri'
require 'active_support/core_ext/string/inflections'

When /^I generate a new Rails application$/ do
  @terminal.cd(TEMP_DIR)
  version_string = ENV['RAILS_VERSION']

  rails3 = version_string =~ /^3/

  if rails3
    rails_create_command = 'new'
  else
    rails_create_command = ''
  end

  load_rails = <<-RUBY
    gem 'rails', '#{version_string}'; \
    load Gem.bin_path('rails', 'rails', '#{version_string}')
  RUBY

  @terminal.run(%{ruby -rrubygems -rthread -e "#{load_rails.strip!}" #{rails_create_command} rails_root})
  if rails_root_exists?
    @terminal.echo("Generated a Rails #{version_string} application")
  else
    raise "Unable to generate a Rails application:\n#{@terminal.output}"
  end
  require_thread
  When %{I configure my application to require the "rake" gem with version "0.8.7"}
  config_gem_dependencies unless rails3
end

When /^I run the airbrake generator with "([^\"]*)"$/ do |generator_args|
  if rails3?
    When %{I run "script/rails generate airbrake #{generator_args}"}
  else
    When %{I run "script/generate airbrake #{generator_args}"}
  end
end

When /^I print the console output$/ do
  puts @terminal.output
end

Given /^I have installed the "([^\"]*)" gem$/ do |gem_name|
  @terminal.install_gem(gem_name)
end

Given /^I have built and installed the "([^\"]*)" gem$/ do |gem_name|
  @terminal.build_and_install_gem(File.join(PROJECT_ROOT, "#{gem_name}.gemspec"))
end

When /^I configure my application to require the "([^\"]*)" gem(?: with version "(.+)")?$/ do |gem_name, version|
  if rails_manages_gems?
    config_gem(gem_name, version)
  elsif bundler_manages_gems?
    bundle_gem(gem_name, version)
  else
    File.open(environment_path, 'a') do |file|
      file.puts
      file.puts("require 'airbrake'")
      file.puts("require 'airbrake/rails'")
    end

    unless rails_finds_generators_in_gems?
      FileUtils.cp_r(File.join(PROJECT_ROOT, 'generators'), File.join(rails_root, 'lib'))
    end
  end
end

When /^I run "([^\"]*)"$/ do |command|
  @terminal.cd(rails_root)
  @terminal.run(command)
end

Then /^I should receive a Airbrake notification$/ do
  Then %{I should see "[Airbrake] Success: Net::HTTPOK"}
end

Then /^I should receive two Airbrake notifications$/ do
  @terminal.output.scan(/\[Airbrake\] Success: Net::HTTPOK/).size.should == 2
end

When /^I configure the Airbrake shim$/ do
  if bundler_manages_gems?
    bundle_gem("sham_rack")
  end

  shim_file = File.join(PROJECT_ROOT, 'features', 'support', 'airbrake_shim.rb.template')
  if rails_supports_initializers?
    target = File.join(rails_root, 'config', 'initializers', 'airbrake_shim.rb')
    FileUtils.cp(shim_file, target)
  else
    File.open(environment_path, 'a') do |file|
      file.puts
      file.write IO.read(shim_file)
    end
  end
end

When /^I configure the notifier to use "([^\"]*)" as an API key$/ do |api_key|
  steps %{
    When I configure the notifier to use the following configuration lines:
      """
      config.api_key = #{api_key.inspect}
      """
  }
end

When /^I configure the notifier to use the following configuration lines:$/ do |configuration_lines|
  if rails_manages_gems?
    requires = ''
  else
    requires = "require 'airbrake'"
  end

  initializer_code = <<-EOF
    #{requires}
    Airbrake.configure do |config|
      #{configuration_lines}
    end
  EOF

  if rails_supports_initializers?
    File.open(rails_initializer_file, 'w') { |file| file.write(initializer_code) }
  else
    File.open(environment_path, 'a') do |file|
      file.puts
      file.puts initializer_code
    end
  end

end

def rails_initializer_file
  File.join(rails_root, 'config', 'initializers', 'airbrake.rb')
end

def rails_non_initializer_airbrake_config_file
  File.join(rails_root, 'config', 'airbrake.rb')
end

Then /^I should see "([^\"]*)"$/ do |expected_text|
  unless @terminal.output.include?(expected_text)
    raise("Got terminal output:\n#{@terminal.output}\n\nExpected output:\n#{expected_text}")
  end
end

Then /^I should not see "([^\"]*)"$/ do |unexpected_text|
  if @terminal.output.include?(unexpected_text)
    raise("Got terminal output:\n#{@terminal.output}\n\nDid not expect the following output:\n#{unexpected_text}")
  end
end

When /^I uninstall the "([^\"]*)" gem$/ do |gem_name|
  @terminal.uninstall_gem(gem_name)
end

When /^I unpack the "([^\"]*)" gem$/ do |gem_name|
  if bundler_manages_gems?
    @terminal.cd(rails_root)
    @terminal.run("bundle pack")
  elsif rails_manages_gems?
    @terminal.cd(rails_root)
    @terminal.run("rake gems:unpack GEM=#{gem_name}")
  else
    vendor_dir = File.join(rails_root, 'vendor', 'gems')
    FileUtils.mkdir_p(vendor_dir)
    @terminal.cd(vendor_dir)
    @terminal.run("gem unpack #{gem_name}")
    gem_path =
      Dir.glob(File.join(rails_root, 'vendor', 'gems', "#{gem_name}-*", 'lib')).first
    File.open(environment_path, 'a') do |file|
      file.puts
      file.puts("$: << #{gem_path.inspect}")
    end
  end
end

When /^I install cached gems$/ do
  if bundler_manages_gems?
    When %{I run "bundle install"}
  end
end

When /^I install the "([^\"]*)" plugin$/ do |plugin_name|
  FileUtils.mkdir_p("#{rails_root}/vendor/plugins/#{plugin_name}")
end

When /^I define a response for "([^\"]*)":$/ do |controller_and_action, definition|
  controller_class_name, action = controller_and_action.split('#')
  controller_name = controller_class_name.underscore
  controller_file_name = File.join(rails_root, 'app', 'controllers', "#{controller_name}.rb")
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
  perform_request(uri)
end

When /^I perform a request to "([^\"]*)" in the "([^\"]*)" environment$/ do |uri, environment|
  perform_request(uri, environment)
end

Given /^the response page for a "([^\"]*)" error is$/ do |error, html|
  File.open(File.join(rails_root, "public", "#{error}.html"), "w") do |file|
    file.write(html)
  end
end

Then /^I should receive the following Airbrake notification:$/ do |table|
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
  doc.should have_content('//server-environment/project-root', hash['project-root']) if hash['project-root']

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

Then /^I should see that "([^\"]*)" is not considered a framework gem$/ do |gem_name|
  Then %{I should not see "[R] #{gem_name}"}
end

Then /^the command should have run successfully$/ do
  @terminal.status.exitstatus.should == 0
end

When /^I route "([^\"]*)" to "([^\"]*)"$/ do |path, controller_action_pair|
  route = if rails3?
            %(match "#{path}", :to => "#{controller_action_pair}")
          else
            controller, action = controller_action_pair.split('#')
            %(map.connect "#{path}", :controller => "#{controller}", :action => "#{action}")
          end
  routes_file = File.join(rails_root, "config", "routes.rb")
  File.open(routes_file, "r+") do |file|
    content = file.read
    content.gsub!(/^end$/, "  #{route}\nend")
    file.rewind
    file.write(content)
  end
end

Then /^"([^\"]*)" should not contain "([^\"]*)"$/ do |file_path, text|
  actual_text = IO.read(File.join(rails_root, file_path))
  if actual_text.include?(text)
    raise "Didn't expect text:\n#{actual_text}\nTo include:\n#{text}"
  end
end

Then /^my Airbrake configuration should contain the following line:$/ do |line|
  configuration_file = if rails_supports_initializers?
    rails_initializer_file
  else
    rails_non_initializer_airbrake_config_file
    # environment_path
  end

  configuration = File.read(configuration_file)
  if ! configuration.include?(line.strip)
    raise "Expected text:\n#{configuration}\nTo include:\n#{line}\nBut it didn't."
  end
end

When /^I set the environment variable "([^\"]*)" to "([^\"]*)"$/ do |environment_variable, value|
  @terminal.environment_variables[environment_variable] = value
end

When /^I configure the Heroku rake shim$/ do
  @terminal.invoke_heroku_rake_tasks_locally = true
end

When /^I configure the Heroku gem shim with "([^\"]*)"( and multiple app support)?$/ do |api_key, multi_app|
  heroku_script_bin = File.join(TEMP_DIR, "bin")
  FileUtils.mkdir_p(heroku_script_bin)
  heroku_script     = File.join(heroku_script_bin, "heroku")
  single_app_script = <<-SINGLE
    #!/bin/bash
    if [[ $1 == 'console' && $2 == 'puts ENV[%{HOPTOAD_API_KEY}]' ]]; then
      echo #{api_key}
    fi
  SINGLE

  multi_app_script = <<-MULTI
    #!/bin/bash
    if [[ $1 == 'console' && $2 == '--app' && $4 == 'puts ENV[%{HOPTOAD_API_KEY}]' ]]; then
      echo #{api_key}
    fi
  MULTI

  File.open(heroku_script, "w") do |f|
    if multi_app
      f.puts multi_app_script
    else
      f.puts single_app_script
    end
  end
  FileUtils.chmod(0755, heroku_script)
  @terminal.prepend_path(heroku_script_bin)
end

When /^I configure the application to filter parameter "([^\"]*)"$/ do |parameter|
  if rails3?
    application_filename = File.join(rails_root, 'config', 'application.rb')
    application_lines = File.open(application_filename).readlines

    application_definition_line       = application_lines.detect { |line| line =~ /Application/ }
    application_definition_line_index = application_lines.index(application_definition_line)

    application_lines.insert(application_definition_line_index + 1,
                             "    config.filter_parameters += [#{parameter.inspect}]")

   File.open(application_filename, "w") do |file|
     file.puts application_lines.join("\n")
   end
  else
   controller_filename = application_controller_filename
   controller_lines = File.open(controller_filename).readlines

   controller_definition_line       = controller_lines.detect { |line| line =~ /ApplicationController/ }
   controller_definition_line_index = controller_lines.index(controller_definition_line)

   controller_lines.insert(controller_definition_line_index + 1,
                           "    filter_parameter_logging #{parameter.inspect}")

   File.open(controller_filename, "w") do |file|
     file.puts controller_lines.join("\n")
   end
  end
end

Then /^I should see the notifier JavaScript for the following:$/ do |table|
  hash = table.hashes.first
  host        = hash['host']        || 'airbrakeapp.com'
  secure      = hash['secure']      || false
  api_key     = hash['api_key']
  environment = hash['environment'] || 'production'

  document_body = '<html>' + @terminal.output.split('<html>').last
  document_body.should include("#{host}/javascripts/notifier.js")

  response = Nokogiri::HTML.parse(document_body)
  response.css("script[type='text/javascript']:last-child").each do |element|
    content = element.content
    content.should include("Airbrake.setKey('#{api_key}');")
    content.should include("Airbrake.setHost('#{host}');")
    content.should include("Airbrake.setEnvironment('#{environment}');")
  end
end

Then "the notifier JavaScript should provide the following errorDefaults:" do |table|
  hash = table.hashes.first

  document_body = '<html>' + @terminal.output.split('<html>').last

  response = Nokogiri::HTML.parse(document_body)
  response.css("script[type='text/javascript']:last-child").each do |element|
    content = element.content

    hash.each do |key, value|
      content.should =~ %r{Airbrake\.setErrorDefaults.*#{key}: "#{value}}m
    end
  end
end

Then /^I should not see notifier JavaScript$/ do
  response = Nokogiri::HTML.parse('<html>' + @terminal.output.split('<html>').last)
  response.at_css("script[type='text/javascript'][src$='/javascripts/notifier.js']").should be_nil
end
