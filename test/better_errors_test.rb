require File.expand_path '../helper', __FILE__
require 'better_errors'

class BetterErrorsTest < Test::Unit::TestCase
  context "when exception occurs" do
    setup do
      @env = { dummy: 'env' }
      @exception = build_exception
      app = ->(env) {raise @exception}
      @stack = BetterErrors::Middleware.new(app)
    end

    should "deliver exception to airbrake" do
      Airbrake.stubs(:notify_or_ignore)
      @stack.call(@env)
      assert_received(Airbrake, :notify_or_ignore) do |expect|
        expect.with(@exception, rack_env: @env)
      end
    end

    should "set airbrake error id in env" do
      @stack.stubs(:notify_airbrake).returns("101010")
      @stack.call(@env)
      assert_equal @env['airbrake.error_id'], "101010"
    end

    should "check if user agent is ignored" do
      @stack.stubs(:ignored_user_agent?)
      @stack.call(@env)
      assert_received(@stack, :ignored_user_agent?) {|expect| expect.with(@env)}
    end

    should "not deliver exception to airbrake if user agent is ignored" do
      @stack.stubs(:ignored_user_agent?).returns(true)
      @stack.call(@env)
      assert_received(Airbrake, :notify_or_ignore) {|expect| expect.never}
    end

    should "proceed with original method call" do
      @stack.stubs(:show_error_page_original)
      @stack.call(@env)
      assert_received(@stack, :show_error_page_original) do |expect|
        expect.with(@env, @exception)
      end
    end
  end
end
