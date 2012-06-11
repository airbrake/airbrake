Feature: Inform the user of the airbrake notice that was just created

  Background:
    Given I successfully run `bundle exec rails new rails_root`
    And I cd to "rails_root"
    And I configure the application to use Airbrake
    And I configure the Airbrake shim

  Scenario: Rescue an exception in a controller
    When I run the airbrake generator with "-k myapikey"
    And I define a response for "TestController#index":
      """
      raise RuntimeError, "some message"
      """
    And the response page for a "500" error is
      """
      <!-- AIRBRAKE ERROR -->
      """
    And I route "/test/index" to "test#index"
    And I perform a request to "http://example.com:123/test/index?param=value" in the "production" environment
    Then I should see "Airbrake Error b6817316-9c45-ed26-45eb-780dbb86aadb"

  Scenario: Rescue an exception in a controller with a custom error string
    When I configure the notifier to use the following configuration lines:
    """
    config.user_information = 'Error #{{ error_id }}'
    """
    And I run the airbrake generator with "-k myapikey"
    And I define a response for "TestController#index":
      """
      raise RuntimeError, "some message"
      """
    And the response page for a "500" error is
      """
      <!-- AIRBRAKE ERROR -->
      """
    And I route "/test/index" to "test#index"
    And I perform a request to "http://example.com:123/test/index?param=value" in the "production" environment
    Then I should see "Error #b6817316-9c45-ed26-45eb-780dbb86aadb"

  Scenario: Don't inform them user
    When I configure the notifier to use the following configuration lines:
    """
    config.user_information = false
    """
    And I run the airbrake generator with "-k myapikey"
    And I define a response for "TestController#index":
      """
      raise RuntimeError, "some message"
      """
    And the response page for a "500" error is
      """
      <!-- AIRBRAKE ERROR -->
      """
    And I route "/test/index" to "test#index"
    And I perform a request to "http://example.com:123/test/index?param=value" in the "production" environment
    Then I should not see "Airbrake Error b6817316-9c45-ed26-45eb-780dbb86aadb"
