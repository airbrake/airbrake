Feature: Install the Gem in a Rails application and enable the JavaScript notifier

  Background:
    Given I have built and installed the "hoptoad_notifier" gem

  Scenario: Include the Javascript notifier when enabled
    When I generate a new Rails application
    And I configure the Hoptoad shim
    And I configure my application to require the "hoptoad_notifier" gem
    When I configure the notifier to use the following configuration lines:
      """
      config.api_key     = "myapikey"
      config.js_notifier = true
      """
    And I define a response for "TestController#index":
      """
        render :text => "<html><head></head><body></body></html>"
      """
    And I route "/test/index" to "test#index"
    And I perform a request to "http://example.com:123/test/index"
    Then I should see the notifier JavaScript for the following:
      | api_key  | environment | host           |
      | myapikey | production  | hoptoadapp.com |

  Scenario: Include the Javascript notifier when enabled using custom configuration settings
    When I generate a new Rails application
    And I configure the Hoptoad shim
    And I configure my application to require the "hoptoad_notifier" gem
    When I configure the notifier to use the following configuration lines:
      """
      config.api_key     = "myapikey!"
      config.host        = "myhoptoad.com"
      config.port        = 3001
      config.js_notifier = true
      """
    And I define a response for "TestController#index":
      """
        render :text => "<html><head></head><body></body></html>"
      """
    And I route "/test/index" to "test#index"
    And I perform a request to "http://example.com:123/test/index"
    Then I should see the notifier JavaScript for the following:
      | api_key   | environment | host               |
      | myapikey! | production  | myhoptoad.com:3001 |

  Scenario: Don't include the Javascript notifier by default
    When I generate a new Rails application
    And I configure the Hoptoad shim
    And I configure my application to require the "hoptoad_notifier" gem
    When I configure the notifier to use the following configuration lines:
      """
      config.api_key = "myapikey!"
      """
    And I define a response for "TestController#index":
      """
        render :text => "<html><head></head><body></body></html>"
      """
    And I route "/test/index" to "test#index"
    And I perform a request to "http://example.com:123/test/index"
    Then I should not see notifier JavaScript

  Scenario: Don't include the Javascript notifier when enabled in non-public environments
    When I generate a new Rails application
    And I configure the Hoptoad shim
    And I configure my application to require the "hoptoad_notifier" gem
    When I configure the notifier to use the following configuration lines:
      """
      config.api_key          = "myapikey!"
      config.js_notifier      = true
      config.environment_name = 'test'
      """
    And I define a response for "TestController#index":
      """
        render :text => "<html><head></head><body></body></html>"
      """
    And I route "/test/index" to "test#index"
    And I perform a request to "http://example.com:123/test/index" in the "test" environment
    Then I should not see notifier JavaScript
