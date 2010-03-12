Then /^"([^\"]*)" should not contain text of "([^\"]*)"$/ do |target_file, contents_file|
  notifier_root      = File.join(File.dirname(__FILE__), '..', '..')
  full_path_contents = File.join(notifier_root, contents_file)
  contents_text      = File.open(full_path_contents).read

  full_path_target = File.join(RAILS_ROOT, target_file)
  target_text      = File.open(full_path_target).read

  target_text.should_not include(contents_text)
end
