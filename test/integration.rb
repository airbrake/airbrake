require File.expand_path '../helper', __FILE__

silence_warnings do
  require 'abstract_controller'
  require 'action_controller'
  require 'action_dispatch'
  require 'active_support/dependencies'
  require 'active_support/core_ext/kernel/reporting'

  require "erb"
  require "action_view"
end

require File.expand_path "../integration/catcher_test", __FILE__
