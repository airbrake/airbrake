require 'test/unit'
require 'rubygems'
require 'ruby-debug'
require 'ruby2ruby'
require 'mocha'
require 'shoulda'
require 'action_controller'
require 'action_controller/test_process'
require 'active_record'
require File.join(File.dirname(__FILE__), "..", "lib", "hoptoad_notifier")

RAILS_ROOT = File.join( File.dirname(__FILE__), "fixtures" )

class HoptoadController < ActionController::Base
  def rescue_action e
    raise e
  end
  
  def do_raise
    raise "Hoptoad"
  end
  
  def do_not_raise
    render :text => "Success"
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
        class ::HoptoadController
          include HoptoadNotifier::Catcher
          def rescue_action e
            rescue_action_in_public e
          end
        end
        assert @controller.methods.include?("inform_hoptoad")
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
