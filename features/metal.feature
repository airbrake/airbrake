Feature: Rescue errors in Rails middleware
  Background:
    Given I successfully run `rails new rails_root -O --skip-gemfile`
    And I cd to "rails_root"
    And I configure the notifier to use the following configuration lines:
    """
      config.api_key = "myapikey"
      config.logger = Logger.new STDOUT
    """
    And I configure the Airbrake shim
    And I append to "app/metal/exploder.rb" with:
    """
      class Exploder
        def call(env)
          raise "Explode!"
        end
      end
    """
    And I remove the file "config/routes.rb"
    And I append to "config/routes.rb" with:
    """
    RailsRoot::Application.routes.draw do
      mount Exploder.new => "/"
    end
    """

  Scenario: It should not report to Airbrake in development
    When I perform a request to "http://example.com:123/metal/index?param=value"
    Then I should not receive a Airbrake notification

  Scenario: It should report to Airbrake in production
    When I perform a request to "http://example.com:123/metal/index?param=value" in the "production" environment
    Then I should receive a Airbrake notification

