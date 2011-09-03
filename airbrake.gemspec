# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "airbrake/version"

Gem::Specification.new do |s|
  s.name        = %q{airbrake}
  s.version     = Airbrake::VERSION.dup
  s.summary     = %q{Send your application errors to our hosted service and reclaim your inbox.}

  s.require_paths = ["lib"]
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")

  s.add_runtime_dependency("builder")
  s.add_runtime_dependency("activesupport")

  s.add_development_dependency("actionpack",    "~> 2.3.8")
  s.add_development_dependency("activerecord",  "~> 2.3.8")
  s.add_development_dependency("activesupport", "~> 2.3.8")
  s.add_development_dependency("bourne",        ">= 1.0")
  s.add_development_dependency("cucumber",      "~> 0.10.6")
  s.add_development_dependency("fakeweb",       "~> 1.3.0")
  s.add_development_dependency("nokogiri",      "~> 1.4.3.1")
  s.add_development_dependency("rspec",         "~> 2.6.0")
  s.add_development_dependency("sham_rack",     "~> 1.3.0")
  s.add_development_dependency("shoulda",       "~> 2.11.3")
  s.add_development_dependency("capistrano",    "~> 2.8.0")

  s.authors = ["thoughtbot, inc"]
  s.email   = %q{support@airbrakeapp.com}
  s.homepage = "http://www.airbrakeapp.com"

  s.platform = Gem::Platform::RUBY
end
