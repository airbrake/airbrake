When /^I generate a new Rails application$/ do
  @terminal.cd(TEMP_DIR)
  version_string = ENV['RAILS_VERSION'] ? "_#{ENV['RAILS_VERSION']}_" : ''
  @terminal.run("rails #{version_string} rails_root")
  @terminal.echo("Generated a Rails #{rails_version} application")
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
  @terminal.output.should include("[Hoptoad] Success: Net::HTTPOK")
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
    raise "Got terminal output:\n#{@terminal.output}\nExpected output:\n#{expected_text}"
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
