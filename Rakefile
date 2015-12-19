require 'rspec/core/rake_task'

task default: 'spec:unit'

namespace :spec do
  RSpec::Core::RakeTask.new(:unit) do |t|
    t.pattern = 'spec/unit/**/*_spec.rb'
  end

  namespace :integration do
    [:rails, :rack, :sinatra].each do |app|
      RSpec::Core::RakeTask.new(app) do |t|
        t.pattern = "spec/integration/#{app}/*_spec.rb"
      end
    end
  end
end
