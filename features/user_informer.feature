Feature: Inform the user of the airbrake notice that was just created

  Background:
    Given I have built and installed the "airbrake" gem

  Scenario: Rescue an exception in a controller
    When I generate a new Rails application
    And I configure the Airbrake shim
    And I configure my application to require the "airbrake" gem
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
    And I perform a request to "http://example.com:123/test/index?param=value"
    Then I should see "Airbrake Error 3799307"

  Scenario: Rescue an exception in a controller with a custom error string
    When I generate a new Rails application
    And I configure the Airbrake shim
    And I configure my application to require the "airbrake" gem
    And I configure the notifier to use the following configuration lines:
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
    And I perform a request to "http://example.com:123/test/index?param=value"
    Then I should see "Error #3799307"

  Scenario: Don't inform them user
    When I generate a new Rails application
    And I configure the Airbrake shim
    And I configure my application to require the "airbrake" gem
    And I configure the notifier to use the following configuration lines:
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
    And I perform a request to "http://example.com:123/test/index?param=value"
    Then I should not see "Airbrake Error 3799307"
