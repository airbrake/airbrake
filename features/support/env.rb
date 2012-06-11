require 'active_support'
require 'nokogiri'
require 'rspec'
require "aruba/cucumber"

PROJECT_ROOT     = File.expand_path(File.join(File.dirname(__FILE__), '..', '..')).freeze
TEMP_DIR         = File.join(PROJECT_ROOT, 'tmp').freeze
LOCAL_RAILS_ROOT = File.join(TEMP_DIR, 'rails_root').freeze
BUILT_GEM_ROOT   = File.join(TEMP_DIR, 'built_gems').freeze
LOCAL_GEM_ROOT   = File.join(TEMP_DIR, 'local_gems').freeze
RACK_FILE        = File.join(TEMP_DIR, 'rack_app.rb').freeze
RACK_GEM_FILE    = File.join(TEMP_DIR, "Gemfile").freeze

Before do
  FileUtils.rm_rf(TEMP_DIR)
  FileUtils.mkdir_p(TEMP_DIR)
  #FileUtils.rm_rf(BUILT_GEM_ROOT)
  FileUtils.rm_rf(LOCAL_RAILS_ROOT)
  #FileUtils.rm_f(RACK_FILE)
  #FileUtils.mkdir_p(BUILT_GEM_ROOT)
end



When /^I reset Bundler environment variable$/ do
  BUNDLE_ENV_VARS.each do |key|
    ENV[key] = nil
  end
end

def prepend_path(path)
  ENV['PATH'] = path + ":" + ENV['PATH']
end
