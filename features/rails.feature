Feature: Install the Gem in a Rails application

  Background:
    Given I have built and installed the "hoptoad_notifier" gem

  Scenario: Use config.gem without vendoring the gem in a Rails application
    When I generate a new Rails application
    And I configure the Hoptoad shim
    And I configure my application to require the "hoptoad_notifier" gem
    And I run "script/generate hoptoad -k myapikey"
    And I run "rake hoptoad:test --trace"
    Then I should receive a Hoptoad notification
