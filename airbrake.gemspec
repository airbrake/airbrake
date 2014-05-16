# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "airbrake/version"

Gem::Specification.new do |s|
  s.name        = %q{airbrake}
  s.version     = Airbrake::VERSION.dup
  s.summary     = %q{Send your application errors to our hosted service and reclaim your inbox.}

  s.require_paths = ["lib"]
  s.executables   << "airbrake"
  s.files         = Dir["{generators/**/*,lib/**/*,rails/**/*,resources/*,script/*}"]  +
    %w(airbrake.gemspec CHANGELOG Gemfile Guardfile INSTALL LICENSE Rakefile README_FOR_HEROKU_ADDON.md README.md TESTED_AGAINST install.rb)
  s.test_files    = Dir.glob("{test,spec,features}/**/*")

  s.add_runtime_dependency("builder")
  s.add_runtime_dependency("multi_json")

  s.add_development_dependency("bourne",        "~> 1.4.0")
  s.add_development_dependency("cucumber-rails","~> 1.1.1")
  s.add_development_dependency("fakeweb",       "~> 1.3.0")
  s.add_development_dependency("nokogiri",      "~> 1.5.0")
  s.add_development_dependency("rspec",         "~> 2.6.0")
  s.add_development_dependency("sham_rack",     "~> 1.3.0")
  s.add_development_dependency("json-schema",   "~> 1.0.12")
  s.add_development_dependency("capistrano",    "~> 2.0")
  s.add_development_dependency("aruba")
  s.add_development_dependency("appraisal")
  s.add_development_dependency("rspec-rails")
  s.add_development_dependency("girl_friday")
  s.add_development_dependency("sucker_punch",   "1.0.2")
  s.add_development_dependency("shoulda-matchers")
  s.add_development_dependency("shoulda-context")
  s.add_development_dependency("pry")
  s.add_development_dependency("coveralls")
  s.add_development_dependency("minitest", ["~> 4.0"])

  s.authors = ["Airbrake"]
  s.email   = %q{support@airbrake.io}
  s.homepage = "http://www.airbrake.io"

  s.platform = Gem::Platform::RUBY
end
