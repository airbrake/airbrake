@no-clobber
Feature: Rescue errors in Rails middleware
  Background:
    Given I successfully run `bundle exec rails new rails_root --without-bundler`
    And I cd to "rails_root"
    And I append "gem 'airbrake', :path => '../../'" to Gemfile
    And I successfully run `bundle install`
    And I configure the Airbrake shim
    And I define a Metal endpoint called "Exploder":
    """
    def self.call(env)
    raise "Explode"
    end
    """

  Scenario: It should not report to Airbrake in development
    When I perform a request to "http://example.com:123/metal/index?param=value"
    Then I should not receive a Airbrake notification

  Scenario: It should report to Airbrake in production
    When I perform a request to "http://example.com:123/metal/index?param=value" in the "production" environment
    Then I should receive a Airbrake notification

