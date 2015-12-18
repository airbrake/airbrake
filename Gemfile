source 'https://rubygems.org'
gemspec

gem 'airbrake-ruby', git: ENV['AIRBRAKE_RUBY_ADDRESS'], branch: 'master'

# Rubocop supports only >=1.9.3
gem 'rubocop', '~> 0.34', require: false unless RUBY_VERSION == '1.9.2'
