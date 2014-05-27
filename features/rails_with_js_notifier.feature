Feature: Install the Gem in a Rails application and enable the JavaScript notifier

  Background:
    Given I successfully run `rails new rails_root -O --skip-gemfile`
    And I cd to "rails_root"
    And I configure the Airbrake shim

  Scenario: Include the Javascript notifier when enabled
    When I configure the notifier to use the following configuration lines:
      """
      config.api_key     = "myapikey"
      """
    And I define a response for "TestController#index":
      """
        render :inline => '<html><head profile="http://example.com"><%= airbrake_javascript_notifier %></head><body></body></html>'
      """
    And I route "/test/index" to "test#index"
    And I perform a request to "http://example.com:123/test/index" in the "production" environment
    Then I should see the notifier JavaScript for the following:
      | api_key  | environment | host           |
      | myapikey | production  | api.airbrake.io |
    And the notifier JavaScript should provide the following errorDefaults:
      | url                           | component | action |
      | http://example.com:123/test/index | test      | index  |

  Scenario: Include the Javascript notifier when enabled using custom configuration settings
    When I configure the notifier to use the following configuration lines:
      """
      config.development_environments = []
      config.api_key     = "myapikey!"
      config.host        = "myairbrake.com"
      config.port        = 3001
      """
    And I define a response for "TestController#index":
      """
        render :inline => '<html><head><%= airbrake_javascript_notifier %></head><body></body></html>'
      """
    And I route "/test/index" to "test#index"
    And I perform a request to "http://example.com:123/test/index"
    Then I should see the notifier JavaScript for the following:
      | api_key   | environment | host               |
      | myapikey! | test  | myairbrake.com:3001 |

  Scenario: Don't include the Javascript notifier by default
    When I configure the notifier to use the following configuration lines:
      """
      config.api_key = "myapikey!"
      """
    And I define a response for "TestController#index":
      """
        render :inline => "<html><head></head><body></body></html>"
      """
    And I route "/test/index" to "test#index"
    And I perform a request to "http://example.com:123/test/index"
    Then I should not see notifier JavaScript

  Scenario: Don't include the Javascript notifier when enabled in non-public environments
    When I configure the notifier to use the following configuration lines:
      """
      config.api_key          = "myapikey!"
      config.environment_name = 'test'
      """
    And I define a response for "TestController#index":
      """
        render :inline => '<html><head><%= airbrake_javascript_notifier %></head><body></body></html>'
      """
    And I route "/test/index" to "test#index"
    And I perform a request to "http://example.com:123/test/index" in the "test" environment
    Then I should not see notifier JavaScript

  Scenario: Use the js_api_key if present
    When I configure the notifier to use the following configuration lines:
      """
      config.api_key     = "myapikey!"
      config.js_api_key     = "myjsapikey!"
      """
    And I define a response for "TestController#index":
      """
        render :inline => '<html><head><%= airbrake_javascript_notifier %></head><body></body></html>'
      """
    And I route "/test/index" to "test#index"
    And I perform a request to "http://example.com:123/test/index" in the "production" environment
    Then I should see the notifier JavaScript for the following:
      | api_key     | environment | host        |
      | myjsapikey! | production  | api.airbrake.io |

  Scenario: Being careful with user's instance variables
    When I configure the notifier to use the following configuration lines:
      """
      config.api_key     = "myapikey"
      """
    And I define a response for "TestController#index":
      """
        @template = "this is some random instance variable"
        render :inline => '<html><head><%= airbrake_javascript_notifier %></head><body></body></html>'
      """
    And I route "/test/index" to "test#index"
    And I perform a request to "http://example.com:123/test/index" in the "production" environment
    Then I should see the notifier JavaScript for the following:
      | api_key  | environment | host           |
      | myapikey | production  | api.airbrake.io |
    And the notifier JavaScript should provide the following errorDefaults:
      | url                           | component | action |
      | http://example.com:123/test/index | test      | index  |
