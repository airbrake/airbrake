Given /^the following Rack app:$/ do |definition|
  File.open(RACK_FILE, 'w') { |file| file.write(definition) }
end

When /^I perform a Rack request to "([^\"]*)"$/ do |url|
  shim_file = File.join(PROJECT_ROOT, 'features', 'support', 'hoptoad_shim.rb.template')
  request_file = File.join(TEMP_DIR, 'rack_request.rb')
  File.open(request_file, 'w') do |file|
    file.puts "require 'rubygems'"
    file.puts IO.read(shim_file)
    file.puts IO.read(RACK_FILE)
    file.puts "env = Rack::MockRequest.env_for(#{url.inspect})"
    file.puts "status, headers, body = app.call(env)"
    file.puts %{puts "HTTP \#{status}"}
    file.puts %{headers.each { |key, value| puts "\#{key}: \#{value}"}}
    file.puts "body.each { |part| print part }"
  end
  @terminal.run("ruby #{request_file}")
end

