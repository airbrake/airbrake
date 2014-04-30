require 'active_support'
require 'nokogiri'
require 'rspec'
require 'aruba/cucumber'
require 'pry'

PROJECT_ROOT          = File.expand_path(File.join(File.dirname(__FILE__), '..', '..')).freeze
TEMP_DIR              = File.join(PROJECT_ROOT, 'tmp').freeze
LOCAL_RAILS_ROOT      = File.join(TEMP_DIR, 'rails_root').freeze
RACK_FILE             = File.join(TEMP_DIR, 'rack_app.rb').freeze
LAST_NOTICE           = File.join(PROJECT_ROOT, 'resources', 'notice.xml')
ORIGINAL_RACK_FILTERS = File.join(PROJECT_ROOT, 'lib', 'airbrake', 'utils', 'rack_filters.rb')

Before do
  FileUtils.rm_rf(LOCAL_RAILS_ROOT)

  reload_rack_filters
end

When /^I reset Bundler environment variable$/ do
  BUNDLE_ENV_VARS.each do |key|
    ENV[key] = nil
  end
end

def prepend_path(path)
  ENV['PATH'] = path + ":" + ENV['PATH']
end

def reload_rack_filters
  original_filters = File.read(ORIGINAL_RACK_FILTERS)

  Dir.mkdir(TEMP_DIR) unless Dir.exist?(TEMP_DIR)

  File.write(File.join(TEMP_DIR, "rack_filters.rb"), 
             original_filters.lines.to_a[1..-2].join("\n"))

  require File.join(TEMP_DIR, "rack_filters.rb")
end
