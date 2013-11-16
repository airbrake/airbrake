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
  end
end

load File.expand_path('../tasks/airbrake.cap', __FILE__)