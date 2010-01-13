PROJECT_ROOT   = File.expand_path(File.join(File.dirname(__FILE__), '..', '..')).freeze
TEMP_DIR       = File.join(PROJECT_ROOT, 'tmp').freeze
RAILS_ROOT     = File.join(TEMP_DIR, 'rails_root').freeze
BUILT_GEM_ROOT = File.join(TEMP_DIR, 'built_gems').freeze
LOCAL_GEM_ROOT = File.join(TEMP_DIR, 'local_gems').freeze

Before do
  FileUtils.mkdir_p(TEMP_DIR)
  FileUtils.rm_rf(BUILT_GEM_ROOT)
  FileUtils.rm_rf(RAILS_ROOT)
  FileUtils.mkdir_p(BUILT_GEM_ROOT)
end
