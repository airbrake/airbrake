%w{3.0.15 3.1.5 3.2.5}.each do |rails_version|
  appraise "#{rails_version}" do
     gem "airbrake", :path => "../"
     gem "rails", rails_version
  end
end
