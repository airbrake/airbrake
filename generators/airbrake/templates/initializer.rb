<% if Rails::VERSION::MAJOR < 3 && Rails::VERSION::MINOR < 2 -%>
require 'airbrake/rails'
<% end -%>
<%= configuration_output %>
