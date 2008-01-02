require 'test/unit'
require 'rubygems'
require 'ruby-debug'
require 'ruby2ruby'
require 'mocha'
require 'shoulda'
require 'action_controller'
require 'action_controller/test_process'
require File.join(File.dirname(__FILE__), "..", "lib", "hoptoad_notifier")

class HoptoadController < ActionController::Base
  def rescue_action e
    puts "rescue_action"
    rescue_action_in_public e
  end
  
  def rescue_action_in_public e
    puts "rescue_action_in_public"
    raise e
  end
  
  def do_raise
    render :text => "raise"
    raise "Hoptoad"
  end
  
  def do_not_raise
    render :text => "no raise"
  end
end

class HoptoadNotifierTest < Test::Unit::TestCase
  def request action = nil, method = :get
    @request = ActionController::TestRequest.new({
      "controller" => "hoptoad",
      "action"     => action ? action.to_s : "",
      "_method"    => method.to_s
    })
    @response = ActionController::TestResponse.new
    @controller.process(@request, @response)
  end

  context "The hoptoad controller" do
    setup do
      @controller = ::HoptoadController.new
    end

    context "with no notifier catcher" do
      should "not prevent raises" do
        assert_raises RuntimeError do
          request("do_raise")
        end
      end

      should "allow a non-raising action to complete" do
        assert_nothing_raised do
          request("do_not_raise")
        end
      end
    end
    
    context "with the notifier installed" do
      setup do
        ::HoptoadController.send(:include, ::HoptoadNotifier::Catcher)
        assert @controller.private_methods.include?("inform_hoptoad")
        debugger
      end
      
      should "prevent raises" do
        @controller.expects(:inform_hoptoad)
        assert_nothing_raised do
          request("do_raise")
        end
      end

      should "allow a non-raising action to complete" do
        assert_nothing_raised do
          request("do_not_raise")
        end
      end
    end
  end

end
