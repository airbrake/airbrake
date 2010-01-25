When /^I define a Metal endpoint called "([^\"]*)":$/ do |class_name, definition|
  FileUtils.mkdir_p(File.join(RAILS_ROOT, 'app', 'metal'))
  file_name = File.join(RAILS_ROOT, 'app', 'metal', "#{class_name.underscore}.rb")
  File.open(file_name, "w") do |file|
    file.puts "class #{class_name}"
    file.puts definition
    file.puts "end"
  end
end

