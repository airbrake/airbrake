Feature: Use the Gem to catch errors in a Rake application

  Background:
    Given I've prepared the Rakefile

  Scenario: Ignoring exceptions
    When I run rake with airbrake ignored
    Then Airbrake should not catch the exception

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

  @wip
  Scenario: Airbrake should also send the command name
    When I run `rake airbrake_autodetect_not_from_terminal`
    Then command "airbrake_autodetect_not_from_terminal" should be reported
