<% if Rails::VERSION::MAJOR < 3 && Rails::VERSION::MINOR < 2 -%>
require 'airbrake/rails'
<% end -%>
Airbrake.configure do |config|
  config.api_key = <%= api_key_expression %>
end
