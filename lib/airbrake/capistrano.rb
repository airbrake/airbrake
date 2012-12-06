# Defines deploy:notify_airbrake which will send information about the deploy to Airbrake.
require 'capistrano'

module Airbrake
  module Capistrano
    # What follows is a copy-paste backport of the shellescape method
    # included in Ruby 1.9 and greater. The FSF's guidance on a snippet
    # of this size indicates that such a small function is not subject
    # to copyright and as such there is no risk of a license conflict:
    # See www.gnu.org/prep/maintain/maintain.html#Legally-Significant
    #
    # Escapes a string so that it can be safely used in a Bourne shell
    # command line.  +str+ can be a non-string object that responds to
    # +to_s+.
    #
    # Note that a resulted string should be used unquoted and is not
    # intended for use in double quotes nor in single quotes.
    #
    #   argv = Shellwords.escape("It's better to give than to receive")
    #   argv #=> "It\\'s\\ better\\ to\\ give\\ than\\ to\\ receive"
    #
    # String#shellescape is a shorthand for this function.
    #
    #   argv = "It's better to give than to receive".shellescape
    #   argv #=> "It\\'s\\ better\\ to\\ give\\ than\\ to\\ receive"
    #
    #   # Search files in lib for method definitions
    #   pattern = "^[ \t]*def "
    #   open("| grep -Ern #{pattern.shellescape} lib") { |grep|
    #     grep.each_line { |line|
    #       file, lineno, matched_line = line.split(':', 3)
    #       # ...
    #     }
    #   }
    #
    # It is the caller's responsibility to encode the string in the right
    # encoding for the shell environment where this string is used.
    #
    # Multibyte characters are treated as multibyte characters, not bytes.
    #
    # Returns an empty quoted String if +str+ has a length of zero.
    def self.shellescape(str)
      str = str.to_s

      # An empty argument will be skipped, so return empty quotes.
      return "''" if str.empty?

      str = str.dup

      # Treat multibyte characters as is.  It is caller's responsibility
      # to encode the string in the right encoding for the shell
      # environment.
      str.gsub!(/([^A-Za-z0-9_\-.,:\/@\n])/, "\\\\\\1")

      # A LF cannot be escaped with a backslash because a backslash + LF
      # combo is regarded as line continuation and simply ignored.
      str.gsub!(/\n/, "'\n'")

      return str
    end

    def self.load_into(configuration)
      configuration.load do
        after "deploy",            "airbrake:deploy"
        after "deploy:migrations", "airbrake:deploy"
        after "deploy:cold",       "airbrake:deploy"

        namespace :airbrake do
          desc <<-DESC
            Notify Airbrake of the deployment by running the notification on the REMOTE machine.
              - Run remotely so we use remote API keys, environment, etc.
          DESC
          task :deploy, :except => { :no_release => true } do
            rails_env = fetch(:rails_env, "production")
            airbrake_env = fetch(:airbrake_env, fetch(:rails_env, "production"))
            local_user = ENV['USER'] || ENV['USERNAME']
            executable = RUBY_PLATFORM.downcase.include?('mswin') ? fetch(:rake, 'rake.bat') : fetch(:rake, 'bundle exec rake ')
            directory = configuration.release_path
            notify_command = "cd #{directory}; #{executable} RAILS_ENV=#{rails_env} airbrake:deploy TO=#{airbrake_env} REVISION=#{current_revision} REPO=#{repository} USER=#{Airbrake::Capistrano::shellescape(local_user)}"
            notify_command << " DRY_RUN=true" if dry_run
            notify_command << " API_KEY=#{ENV['API_KEY']}" if ENV['API_KEY']
            logger.info "Notifying Airbrake of Deploy (#{notify_command})"
            if configuration.dry_run
              logger.info "DRY RUN: Notification not actually run."
            else
              result = ""
              run(notify_command, :once => true) { |ch, stream, data| result << data }
              # TODO: Check if SSL is active on account via result content.
            end
            logger.info "Airbrake Notification Complete."
          end
        end
      end
    end
  end
end

if Capistrano::Configuration.instance
  Airbrake::Capistrano.load_into(Capistrano::Configuration.instance)
end
