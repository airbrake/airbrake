require 'uri'

require 'active_support/core_ext/string/inflections'

Given /^Airbrake server is not responding$/ do
  content = <<-CONTENT
  require 'sham_rack'

  ShamRack.at("api.airbrake.io") {["500", { "Content-type" => "text/xml" }, ["Internal server error"]]}

  CONTENT
  target = File.join(rails_root, 'config', 'initializers', 'airbrake_shim.rb')
  File.open(target,"w") { |f| f.write content }
end

Then /^I should (?:(not ))?receive a Airbrake notification$/ do |negator|
  steps %{
    Then the output should #{negator}contain "** [Airbrake] Response from Airbrake:"
    And the output should #{negator}contain "b6817316-9c45-ed26-45eb-780dbb86aadb"
    And the output should #{negator}contain "http://airbrake.io/locate/b6817316-9c45-ed26-45eb-780dbb86aadb"
  }
end

Then /^I should receive two Airbrake notifications$/ do
  step %{the output should match /\[Airbrake\] Response from Airbrake:/}
end

When /^I configure the Airbrake shim$/ do
  shim_file = File.join(PROJECT_ROOT, 'features', 'support', 'airbrake_shim.rb.template')
  target = File.join(rails_root, 'config', 'initializers', 'airbrake_shim.rb')
  FileUtils.cp(shim_file, target)
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
  initializer_code = <<-EOF
    Airbrake.configure do |config|
      config.test_mode = true
      #{configuration_lines}
    end
  EOF

  File.open(rails_initializer_file, 'w') { |file| file.write(initializer_code) }
end

def rails_initializer_file
  File.join(rails_root, 'config', 'initializers', 'airbrake.rb')
end

def rails_non_initializer_airbrake_config_file
  File.join(rails_root, 'config', 'airbrake.rb')
end

Then /^I should (?:(not ))?see "([^\"]*)"$/ do |negator,expected_text|
  step %{the output should #{negator}contain "#{expected_text}"}
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
  step %{I run `bundle exec rails runner request.rb`}
end

When /^I perform a request to "([^\"]*)" in the "([^\"]*)" environment$/ do |uri, environment|
  perform_request(uri,environment)
  step %{I run `bundle exec rails runner -e #{environment} request.rb`}
end

Given /^the response page for a "([^\"]*)" error is$/ do |error, html|
  File.open(File.join(rails_root, "public", "#{error}.html"), "w") do |file|
    file.write(html)
  end
end

Then /^I should see the Rails version$/ do
  step %{I should see "Rails: #{ENV["RAILS_VERSION"]}"}
end

Then /^I should see that "([^\"]*)" is not considered a framework gem$/ do |gem_name|
  step %{I should not see "[R] #{gem_name}"}
end

When /^I route "([^\"]*)" to "([^\"]*)"$/ do |path, controller_action_pair|
  route = %(get "#{path}", :to => "#{controller_action_pair}")
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
  configuration_file = rails_initializer_file

  configuration = File.read(configuration_file)
  if ! configuration.include?(line.strip)
    raise "Expected text:\n#{configuration}\nTo include:\n#{line}\nBut it didn't."
  end
end

When /^I configure the Heroku shim with "([^\"]*)"( and multiple app support)?$/ do |api_key, multi_app|
  heroku_script_bin = File.join(TEMP_DIR, "bin")
  FileUtils.mkdir_p(heroku_script_bin)
  heroku_script     = File.join(heroku_script_bin, "heroku")
  heroku_env_vars = <<-VARS
AIRBRAKE_API_KEY    => myapikey
  APP_NAME            => cold-moon-2929
  BUNDLE_WITHOUT      => development:test
  COMMIT_HASH         => lj32j42ss9332jfa2
  DATABASE_URL        => postgres://fchovwjcyb:QLPVWmBBbf4hCG_YMrtV@ec3-107-28-193-23.compute-1.amazonaws.com/fhcvojwwcyb
  LANG                => en_US.UTF-8
  LAST_GIT_BY         => kensa
  RACK_ENV            => production
  SHARED_DATABASE_URL => postgres://fchovwjcyb:QLPVwMbbbF8Hcg_yMrtV@ec2-94-29-181-224.compute-1.amazonaws.com/fhcvojcwwyb
  STACK               => bamboo-mri-1.9.2
  URL                 => cold-moon-2929.heroku.com
  VARS
  single_app_script = <<-SINGLE
#!/bin/bash
if [ $1 == 'config' ]
then
  echo "#{heroku_env_vars}"
fi
  SINGLE

  multi_app_script = <<-MULTI
#!/bin/bash
if [[ $1 == 'config' && $2 == '--app' ]]
then
  echo "#{heroku_env_vars}"
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
  prepend_path(heroku_script_bin)
end

When /^I configure the application to filter parameter "([^\"]*)"$/ do |parameter|
  application_filename = File.join(rails_root, 'config', 'application.rb')
  application_lines = File.open(application_filename).readlines

  application_definition_line       = application_lines.detect { |line| line =~ /Application/ }
  application_definition_line_index = application_lines.index(application_definition_line)

  application_lines.insert(application_definition_line_index + 1,
                           "    config.filter_parameters += [#{parameter.inspect}]")

  File.open(application_filename, "w") do |file|
    file.puts application_lines.join("\n")
  end
end

When /^I have set up authentication system in my app that uses "([^\"]*)"$/ do |current_user|
  application_controller = File.join(rails_root, 'app', 'controllers', "application_controller.rb")
  definition =
    """
  class ApplicationController < ActionController::Base
    def consider_all_requests_local; false; end
    def local_request?; false; end

    # this is the ultimate authentication system, devise is history
    def #{current_user}
      Struct.new(:id, :name, :email, :username, :class_name).new(1, 'Bender', 'bender@beer.com', 'b3nd0r', 'User')
    end
  end
  """
  File.open(application_controller, "w") {|file| file.puts definition }
end

Then /^the Airbrake notification should contain "([^\"]*)"$/ do |content|
  step %{the last notice sent should contain "#{content}"}
end

Then /^the Airbrake notification should not contain "([^\"]*)"$/ do |content|
  step %{the last notice sent should not contain "#{content}"}
end

Then /^the Airbrake notification should contain the custom user details$/ do
  step %{the last notice sent should contain "<name>Bender</name>"}
  step %{the last notice sent should contain "<email>bender@beer.com</email>"}
  step %{the last notice sent should contain "<username>b3nd0r</username>"}
end

Then /^the Airbrake notification should contain user details$/ do
  step %{the last notice sent should contain "<id>1</id>"}
end

Then /^the Airbrake notification should not contain any of the sensitive Rack variables$/ do
  sensitive_rack_data_regex = FILTERED_RACK_VARS.map do |var|
    var.instance_of?(Regexp) ? var : Regexp.quote(var)
  end.join("|")
  step %{the last notice sent should not contain keys with "#{sensitive_rack_data_regex}"}
end

Then /^the last notice sent should contain "([^\"]*)"$/ do |data|
  last_notice = File.read(LAST_NOTICE)
  last_notice.should match(%r{#{data}})
end

Then /^the last notice sent should not contain "([^\"]*)"$/ do |data|
  last_notice = File.read(LAST_NOTICE)
  last_notice.should_not match(%r{#{data}})
end

Then /^the last notice sent should not contain keys with "([^\"]*)"$/ do |data|
  last_notice = File.read(LAST_NOTICE)
  last_notice.should_not match(%r{key\=\"(#{data})\"})
end

Then /^the Airbrake notification should contain the framework information$/ do
  step %{the last notice sent should contain "Rails: #{ENV["RAILS_VERSION"]}"}
end

When /^I list the application's middleware and save it into a file$/ do
  step %{I run `bash -c 'bundle exec rake middleware > middleware.dump'`}
end

Then /^the Airbrake middleware should be placed correctly$/ do
  middleware_file = File.join(LOCAL_RAILS_ROOT, 'middleware.dump')
  middleware      = File.read(middleware_file).split(/\n/)
  airbrake_index  = middleware.rindex("use Airbrake::Rails::Middleware")
  middleware_index = middleware.rindex("use ActionDispatch::DebugExceptions") ||
    middleware.rindex("use ActionDispatch::ShowExceptions")
  (airbrake_index > middleware_index).should be_true
end
