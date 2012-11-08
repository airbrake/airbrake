Given /I've prepared the Rakefile/ do
  rakefile = File.join(PROJECT_ROOT, 'features', 'support', 'rake', 'Rakefile')
  target = File.join(TEMP_DIR, 'Rakefile')
  FileUtils.cp(rakefile, target)
end

When /I run rake with (.+)/ do |command|
  command = "rake #{command.gsub(' ','_')}"
  step %{I run `#{command}`}
end

Then "Airbrake should not catch the exception" do
  step %{I should not see "[airbrake]"}
end

Then "Airbrake should catch the exception" do
  step %{I should see "[airbrake]"}
end

Then /^command "(.*?)" should be reported$/ do |command_name|
  step %{the output should contain "[airbrake] rake #{command_name}"}
end
