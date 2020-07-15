# frozen_string_literal: true

if defined?(Capistrano::VERSION) &&
   Gem::Version.new(Capistrano::VERSION).release >= Gem::Version.new('3.0.0')
  require 'airbrake/capistrano/capistrano3/deploy'
  require 'airbrake/capistrano/capistrano3/sourcemaps'
else
  require 'airbrake/capistrano/capistrano2'
end
