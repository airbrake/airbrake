Feature: Use the Gem to catch errors in a Rake application
  Background:
    Given I have built and installed the "hoptoad_notifier" gem

  Scenario: Catching exceptions in Rake
    When I run rake with hoptoad
    Then Hoptoad should catch the exception

  Scenario: Disabling Rake exception catcher
    When I run rake with hoptoad disabled
    Then Hoptoad should not catch the exception

  Scenario: Autodetect, running from terminal
    When I run rake with hoptoad autodetect from terminal
    Then Hoptoad should not catch the exception
  
  Scenario: Autodetect, not running from terminal
    When I run rake with hoptoad autodetect not from terminal
    Then Hoptoad should catch the exception

  Scenario: Sendind the correct component name
    When I run rake with hoptoad
    Then Hoptoad should send the rake command line as the component name
