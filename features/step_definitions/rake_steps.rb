When /I run rake with (.+)/ do |command|
  @rake_command = "rake #{command.gsub(' ','_')}"
  @rake_result = `cd features/support/rake && GEM_HOME=#{BUILT_GEM_ROOT} #{@rake_command} 2>&1`
end

Then /Airbrake should (|not) ?catch the exception/ do |condition|
  if condition=='not'
    @rake_result.should_not =~ /^airbrake/
  else
    @rake_result.should =~ /^airbrake/
  end
end

Then /Airbrake should send the rake command line as the component name/ do
  component = @rake_result.match(/^airbrake (.*)$/)[1]
  component.should == @rake_command
end
