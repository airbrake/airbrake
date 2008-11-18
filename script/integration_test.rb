#!/usr/bin/env ruby

# This file must _not_ end in test.rb, or it will get run every time.
require File.join(File.dirname(__FILE__), "..", "lib", "hoptoad_notifier")

#fail ARGV.inspect
fail "Please supply an API Key as the first argument" if ARGV.empty?

RAILS_ENV = "production"
RAILS_ROOT = "./"

host = ARGV[1]
host ||= "hoptoadapp.com"

HoptoadNotifier.configure do |config|
  config.host = host
  config.api_key = ARGV.first
end

exception = begin
              raise 'Testing hoptoad notifier. If you can see this, it works.'
            rescue => foo
              foo
            end

puts "Sending notification to project with key #{ARGV.first}"
HoptoadNotifier.notify(exception)

