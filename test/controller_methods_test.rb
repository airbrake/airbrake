require File.expand_path '../helper', __FILE__

require 'airbrake/rails/controller_methods'
class TestController
  include Airbrake::Rails::ControllerMethods

  def params; {}; end
  def session; nil; end
  def request
    OpenStruct.new(:port=> 80, :protocol => 'http://', host: 'example.com', :fullpath => 'path', :env => [])
  end
end

class NilUserTestController < TestController
  def current_user
    nil
  end
end

class CurrentUserTestController < TestController
  def current_user
    OpenStruct.new(:id => 123, :name => 'tape')
  end
end

class CurrentMemberTestController < TestController
  def current_member
    OpenStruct.new(:id => 321, :name => 'mamba')
  end
end


class NoSessionTestController < TestController
  def session
    nil
  end
end

class ControllerMethodsTest < Test::Unit::TestCase
  include DefinesConstants

  context "#airbrake_current_user" do
    context "without a logged in user" do
      setup do

        NilClass.class_eval do
          @@called = false

          def self.called
            !! @@called
          end

          def id
            @@called = true
          end
        end

        @controller = NilUserTestController.new
      end

      should "not call #id on NilClass" do
        @controller.send(:airbrake_current_user)
        assert_equal false, NilClass.called
      end
    end

    context "with a logged in User" do
      teardown do
        Object.__send__(:remove_const, :ActiveRecord) if defined?(ActiveRecord)
        Object.__send__(:remove_const, :POOL) if defined?(POOL)
      end
      should 'include user info in the data sent to Ab' do
        Airbrake.configuration.user_attributes = %w(id)
        controller = CurrentUserTestController.new
        ab_data = controller.airbrake_request_data

        assert_equal( {:id => 123},  ab_data[:user])
      end

      should 'include more info if asked to, discarding unknown attributes' do
        Airbrake.configuration.user_attributes = %w(id name collar-size)

        controller = CurrentUserTestController.new
        ab_data = controller.airbrake_request_data

        assert_equal( {:id => 123, :name => 'tape'},  ab_data[:user])
      end

      should 'work with a "current_member" method too' do
        Airbrake.configuration.user_attributes = %w(id)
        controller = CurrentMemberTestController.new
        ab_data = controller.airbrake_request_data

        assert_equal( {:id => 321},  ab_data[:user])
      end

      should "release DB connections" do
        ::POOL = Object.new
        module ::ActiveRecord; class Base; def self.connection_pool; ::POOL; end; end; end
        ::POOL.expects(:release_connection)

        CurrentUserTestController.new.airbrake_request_data
      end
    end
  end

  context '#airbrake_session_data' do
    setup do
      @controller = NoSessionTestController.new
    end
    should 'not call session if no session' do
      no_session = @controller.send(:airbrake_session_data)
      assert_equal no_session, {:session => 'no session found'}
    end
  end

  context "#airbrake_request_url" do
    setup do
      @controller = NoSessionTestController.new
    end
    should "return correct request url" do
      request_url = @controller.send(:airbrake_request_url)
      assert_equal request_url, "http://example.com/path"
    end
  end

  context "Rails 3" do
    setup do
      @controller = NilUserTestController.new
      ::Rails = Object.new
      ::Rails.stubs(:version).returns("3.2.17")
    end

    should "respond to rails_3_or_4? with true" do
      assert @controller.send(:rails_3_or_4?)
    end

    should "call filter_rails3_parameters" do
      hash = {:a => "b"}
      filtered_hash = {:c => "d"}

      @controller.expects(:filter_rails3_parameters).with(hash).
        returns(filtered_hash)
      assert_equal filtered_hash,
        @controller.send(:airbrake_filter_if_filtering, hash)
    end
  end

  context "Rails 4.x" do
    setup do
      @controller = TestController.new
      ::Rails = Object.new
      ::Rails.stubs(:version).returns("4.5.6.7")
    end

    should 'be true when running Rails 4.x' do
      assert @controller.send(:rails_3_or_4?)
    end

    should "call filter_rails3_parameters" do
      hash = {:a => "b"}
      filtered_hash = {:c => "d"}

      @controller.expects(:filter_rails3_parameters).with(hash).
        returns(filtered_hash)
      assert_equal filtered_hash,
        @controller.send(:airbrake_filter_if_filtering, hash)
    end
  end

end
