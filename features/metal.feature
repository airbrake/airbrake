Feature: Rescue errors in Rails middleware

  Background:
    Given I have built and installed the "airbrake" gem
    And I generate a new Rails application
    And I configure the Airbrake shim
    And I configure my application to require the "airbrake" gem
    And I run "script/generate airbrake -k myapikey"

  Scenario: Rescue an exception in the dispatcher
    When I define a Metal endpoint called "Exploder":
      """
      def self.call(env)
        raise "Explode"
      end
      """
    When I perform a request to "http://example.com:123/metal/index?param=value"
    Then I should receive the following Airbrake notification:
      | error message | RuntimeError: Explode                         |
      | error class   | RuntimeError                                  |
      | parameters    | param: value                                  |
      | url           | http://example.com:123/metal/index?param=value |

