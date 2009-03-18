require 'test/unit'
require 'rubygems'
require 'mocha'
gem 'thoughtbot-shoulda', ">= 2.0.0"
require 'shoulda'

$LOAD_PATH << File.join(File.dirname(__FILE__), *%w[.. vendor ginger lib])
require 'ginger'

require 'action_controller'
require 'action_controller/test_process'
require 'active_record'
require 'active_record/base'
require 'active_support'
require 'active_support/test_case'

require File.join(File.dirname(__FILE__), "..", "lib", "hoptoad_notifier")

RAILS_ROOT = File.join( File.dirname(__FILE__), "rails_root" )
RAILS_ENV  = "test"

begin require 'redgreen'; rescue LoadError; end

module TestMethods
  def rescue_action e
    raise e
  end

  def do_raise
    raise "Hoptoad"
  end

  def do_not_raise
    render :text => "Success"
  end

  def do_raise_ignored
    raise ActiveRecord::RecordNotFound.new("404")
  end

  def do_raise_not_ignored
    raise ActiveRecord::StatementInvalid.new("Statement invalid")
  end

  def manual_notify
    notify_hoptoad(Exception.new)
    render :text => "Success"
  end

  def manual_notify_ignored
    notify_hoptoad(ActiveRecord::RecordNotFound.new("404"))
    render :text => "Success"
  end
end

class HoptoadController < ActionController::Base
  include TestMethods
end

def request(action = nil, method = :get, user_agent = nil)
  @request = ActionController::TestRequest.new
  @request.action = action ? action.to_s : ""
  @request.user_agent = user_agent unless user_agent.nil?
  @response = ActionController::TestResponse.new
  @controller.process(@request, @response)
end
