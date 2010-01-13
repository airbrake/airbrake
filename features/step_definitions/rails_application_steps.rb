When /^I generate a new Rails application$/ do
  @terminal.cd(TEMP_DIR)
  @terminal.run("rails rails_root")
end

Given /^I have installed the "([^\"]*)" gem$/ do |gem_name|
  @terminal.install_gem(gem_name)
end

Given /^I have built and installed the "([^\"]*)" gem$/ do |gem_name|
  @terminal.build_and_install_gem(File.join(PROJECT_ROOT, "#{gem_name}.gemspec"))
end

When /^I configure my application to require the "([^\"]*)" gem$/ do |gem_name|
  path = File.join(RAILS_ROOT, 'config', 'environment.rb')
  run = "Rails::Initializer.run do |config|"
  insert = "  config.gem '#{gem_name}'"
  content = File.read(path)
  if content.sub!(run, "#{run}\n#{insert}")
    File.open(path, 'wb') { |file| file.write(content) }
  else
    raise "Couldn't find #{run.inspect} in #{path}"
  end
end

When /^I run "([^\"]*)"$/ do |command|
  @terminal.cd(RAILS_ROOT)
  @terminal.run(command)
end

Then /^I should receive a Hoptoad notification$/ do
  @terminal.output.should include("[Hoptoad] Success: Net::HTTPOK")
end

When /^I configure the Hoptoad shim$/ do
  shim_file = File.join(PROJECT_ROOT, 'features', 'support', 'hoptoad_shim.rb.template')
  target = File.join(RAILS_ROOT, 'config', 'initializers', 'hoptoad_shim.rb')
  FileUtils.cp(shim_file, target)
end

When /^I configure the notifier to use "([^\"]*)" as an API key$/ do |api_key|
  config_file = File.join(RAILS_ROOT, 'config', 'initializers', 'hoptoad.rb')
  File.open(config_file, 'w') do |file|
    file.write(<<-EOF)
      HoptoadNotifier.configure do |config|
        config.api_key = #{api_key.inspect}
      end
    EOF
  end
end

Then /^I should see "([^\"]*)"$/ do |expected_text|
  @terminal.output.should include(expected_text)
end
