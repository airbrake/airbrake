require 'active_support'
require 'nokogiri'
require 'spec'

PROJECT_ROOT   = File.expand_path(File.join(File.dirname(__FILE__), '..', '..')).freeze
TEMP_DIR       = File.join(PROJECT_ROOT, 'tmp').freeze
RAILS_ROOT     = File.join(TEMP_DIR, 'rails_root').freeze
BUILT_GEM_ROOT = File.join(TEMP_DIR, 'built_gems').freeze
LOCAL_GEM_ROOT = File.join(TEMP_DIR, 'local_gems').freeze
RACK_FILE      = File.join(TEMP_DIR, 'rack_app.rb').freeze

Before do
  FileUtils.mkdir_p(TEMP_DIR)
  FileUtils.rm_rf(BUILT_GEM_ROOT)
  FileUtils.rm_rf(RAILS_ROOT)
  FileUtils.rm_f(RACK_FILE)
  FileUtils.mkdir_p(BUILT_GEM_ROOT)
end
