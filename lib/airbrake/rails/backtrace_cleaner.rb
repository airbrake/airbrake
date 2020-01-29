# frozen_string_literal: true

module Airbrake
  module Rails
    # BacktraceCleaner is a wrapper around Rails.backtrace_cleaner.
    class BacktraceCleaner
      def self.clean(backtrace)
        ::Rails.backtrace_cleaner.clean(backtrace).first(1)
      end
    end
  end
end
