Feature: Use the Gem to catch errors in a Rake application
  Background:
    Given I have built and installed the "airbrake" gem

  Scenario: Catching exceptions in Rake
    When I run rake with airbrake
    Then Airbrake should catch the exception

  Scenario: Falling back to default handler before Airbrake is configured
    When I run rake with airbrake not yet configured
    Then Airbrake should not catch the exception

  Scenario: Disabling Rake exception catcher
    When I run rake with airbrake disabled
    Then Airbrake should not catch the exception

  Scenario: Autodetect, running from terminal
    When I run rake with airbrake autodetect from terminal
    Then Airbrake should not catch the exception
  
  Scenario: Autodetect, not running from terminal
    When I run rake with airbrake autodetect not from terminal
    Then Airbrake should catch the exception

  Scenario: Sendind the correct component name
    When I run rake with airbrake
    Then Airbrake should send the rake command line as the component name
