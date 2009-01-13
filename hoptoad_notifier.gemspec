Gem::Specification.new do |s|
  s.name     = "hoptoad_notifier"
  s.version  = "1.1"
  s.date     = "2008-12-31"
  s.summary  = "Rails plugin that reports exceptions to Hoptoad."
  s.email    = "info@thoughtbot.com"
  s.homepage = "http://github.com/thoughtbot/hoptoad_notifier"
  s.description = "Rails plugin that reports exceptions to Hoptoad."
  s.has_rdoc = true
  s.authors  = "Thoughtbot"
  s.files    = [
    "INSTALL",
    "lib/hoptoad_notifier.rb",
    "Rakefile",
    "README",
    "tasks/hoptoad_notifier_tasks.rake",
    ]
  s.test_files = [
    "test/hoptoad_notifier_test.rb"
    ]
end
