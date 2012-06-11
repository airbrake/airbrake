RAILS_VERSIONS = IO.read('SUPPORTED_RAILS_VERSIONS').strip.split("\n")

RAILS_VERSIONS.each do |rails_version|
  appraise "#{rails_version}" do
     gem "airbrake", :path => "../"
     gem "rails", rails_version
  end
end
