When /^I define a Metal endpoint called "([^\"]*)":$/ do |class_name, definition|
  FileUtils.mkdir_p(File.join(rails_root, 'app', 'metal'))
  step %{I run `mkdir -p app/metal`}
  step %{I cd to "app/metal"}
  file_name = "#{class_name.underscore}.rb"
  contents = <<-CONTENTS
  class #{class_name}
    #{definition}
  end
  CONTENTS
  append_to(file_name,contents)
  if rails3?
    step %{the metal endpoint "#{class_name}" is mounted in the Rails 3 routes.rb} if rails3?
  else
    puts "this is not rails 3!"
  end
end

When /^the metal endpoint "([^\"]*)" is mounted in the Rails 3 routes.rb$/ do |class_name|
  routesrb = File.join(rails_root, "config", "routes.rb")
  routes = IO.readlines(routesrb)
  rack_route = "match '/metal(/*other)' => #{class_name}"
  routes = routes[0..-2] + [rack_route, routes[-1]]
  File.open(routesrb, "w") do |f|
    f.puts "require Rails.root + 'app/metal/#{class_name.underscore}'"
    routes.each do |route_line|
      f.puts route_line
    end
  end
end
