require 'ginger'

Ginger.configure do |config|
  rails_2_2_2 = Ginger::Scenario.new
  rails_2_2_2[/rails/] = "2.2.2"

  rails_2_3_1 = Ginger::Scenario.new
  rails_2_3_1[/rails/] = "2.3.1"

  config.scenarios << rails_2_2_2 << rails_2_3_1
end
