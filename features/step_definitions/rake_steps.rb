When /I run rake with (.+)/ do |command|
  @rake_command = "rake #{command.gsub(' ','_')}"
  @rake_result = `cd features/support/rake && GEM_HOME=#{BUILT_GEM_ROOT} #{@rake_command} 2>&1`
end

Then /Hoptoad should (|not) ?catch the exception/ do |condition|
  if condition=='not'
    @rake_result.should_not =~ /^hoptoad/
  else
    @rake_result.should =~ /^hoptoad/
  end
end

Then /Hoptoad should send the rake command line as the component name/ do
  component = @rake_result.match(/^hoptoad (.*)$/)[1]
  component.should == @rake_command
end
