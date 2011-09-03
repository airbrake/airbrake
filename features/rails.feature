Feature: Install the Gem in a Rails application

  Background:
    Given I have built and installed the "airbrake" gem

  Scenario: Use the gem without vendoring the gem in a Rails application
    When I generate a new Rails application
    And I configure the Airbrake shim
    And I configure my application to require the "airbrake" gem
    And I run the airbrake generator with "-k myapikey"
    Then the command should have run successfully
    And I should receive a Airbrake notification
    And I should see the Rails version

  Scenario: vendor the gem and uninstall
    When I generate a new Rails application
    And I configure the Airbrake shim
    And I configure my application to require the "airbrake" gem
    And I unpack the "airbrake" gem
    And I run the airbrake generator with "-k myapikey"
    Then the command should have run successfully
    When I uninstall the "airbrake" gem
    And I install cached gems
    And I run "rake airbrake:test"
    Then I should see "** [Airbrake] Success: Net::HTTPOK"
    And I should receive two Airbrake notifications

  Scenario: Configure the notifier by hand
    When I generate a new Rails application
    And I configure the Airbrake shim
    And I configure the notifier to use "myapikey" as an API key
    And I configure my application to require the "airbrake" gem
    And I run the airbrake generator with ""
    Then I should receive a Airbrake notification

  Scenario: Configuration within initializer isn't overridden by Railtie
    When I generate a new Rails application
    And I configure the Airbrake shim
    And I configure my application to require the "airbrake" gem
    And I run the airbrake generator with "-k myapikey"
    Then the command should have run successfully
    When I configure the notifier to use the following configuration lines:
      """
      config.api_key = "myapikey"
      config.project_root = "argle/bargle"
      """
    And I define a response for "TestController#index":
      """
      session[:value] = "test"
      raise RuntimeError, "some message"
      """
    And I route "/test/index" to "test#index"
    And I perform a request to "http://example.com:123/test/index?param=value"
    Then I should receive the following Airbrake notification:
      | project-root | argle/bargle |

  Scenario: Try to install without an api key
    When I generate a new Rails application
    And I configure my application to require the "airbrake" gem
    And I run the airbrake generator with ""
    Then I should see "Must pass --api-key or --heroku or create config/initializers/airbrake.rb"

  Scenario: Configure and deploy using only installed gem
    When I generate a new Rails application
    And I run "capify ."
    And I configure the Airbrake shim
    And I configure my application to require the "airbrake" gem
    And I run the airbrake generator with "-k myapikey"
    And I run "cap -T"
    Then I should see "airbrake:deploy"

  Scenario: Configure and deploy using only vendored gem
    When I generate a new Rails application
    And I run "capify ."
    And I configure the Airbrake shim
    And I configure my application to require the "airbrake" gem
    And I unpack the "airbrake" gem
    And I run the airbrake generator with "-k myapikey"
    And I uninstall the "airbrake" gem
    And I install cached gems
    And I run "cap -T"
    Then I should see "airbrake:deploy"

  Scenario: Try to install when the airbrake plugin still exists
    When I generate a new Rails application
    And I install the "airbrake" plugin
    And I configure the Airbrake shim
    And I configure the notifier to use "myapikey" as an API key
    And I configure my application to require the "airbrake" gem
    And I run the airbrake generator with ""
    Then I should see "You must first remove the airbrake plugin. Please run: script/plugin remove airbrake"

  Scenario: Rescue an exception in a controller
    When I generate a new Rails application
    And I configure the Airbrake shim
    And I configure my application to require the "airbrake" gem
    And I run the airbrake generator with "-k myapikey"
    And I define a response for "TestController#index":
      """
      session[:value] = "test"
      raise RuntimeError, "some message"
      """
    And I route "/test/index" to "test#index"
    And I perform a request to "http://example.com:123/test/index?param=value"
    Then I should receive the following Airbrake notification:
      | component     | test                                          |
      | action        | index                                         |
      | error message | RuntimeError: some message                    |
      | error class   | RuntimeError                                  |
      | session       | value: test                                   |
      | parameters    | param: value                                  |
      | url           | http://example.com:123/test/index?param=value |

  Scenario: The gem should not be considered a framework gem
    When I generate a new Rails application
    And I configure the Airbrake shim
    And I configure my application to require the "airbrake" gem
    And I run the airbrake generator with "-k myapikey"
    And I run "rake gems"
    Then I should see that "airbrake" is not considered a framework gem

  Scenario: The app uses Vlad instead of Capistrano
    When I generate a new Rails application
    And I configure the Airbrake shim
    And I configure my application to require the "airbrake" gem
    And I run "touch config/deploy.rb"
    And I run "rm Capfile"
    And I run the airbrake generator with "-k myapikey"
    Then "config/deploy.rb" should not contain "capistrano"

  Scenario: Support the Heroku addon in the generator
    When I generate a new Rails application
    And I configure the Airbrake shim
    And I configure the Heroku rake shim
    And I configure the Heroku gem shim with "myapikey"
    And I configure my application to require the "airbrake" gem
    And I run the airbrake generator with "--heroku"
    Then the command should have run successfully
    And I should receive a Airbrake notification
    And I should see the Rails version
    And my Airbrake configuration should contain the following line:
      """
      config.api_key = ENV['HOPTOAD_API_KEY']
      """

  Scenario: Support the --app option for the Heroku addon in the generator
    When I generate a new Rails application
    And I configure the Airbrake shim
    And I configure the Heroku rake shim
    And I configure the Heroku gem shim with "myapikey" and multiple app support
    And I configure my application to require the "airbrake" gem
    And I run the airbrake generator with "--heroku -a myapp"
    Then the command should have run successfully
    And I should receive a Airbrake notification
    And I should see the Rails version
    And my Airbrake configuration should contain the following line:
      """
      config.api_key = ENV['HOPTOAD_API_KEY']
      """

  Scenario: Filtering parameters in a controller
    When I generate a new Rails application
    And I configure the Airbrake shim
    And I configure my application to require the "airbrake" gem
    And I run the airbrake generator with "-k myapikey"
    When I configure the notifier to use the following configuration lines:
      """
      config.api_key = "myapikey"
      config.params_filters << "credit_card_number"
      """
    And I define a response for "TestController#index":
      """
      params[:credit_card_number] = "red23"
      raise RuntimeError, "some message"
      """
    And I route "/test/index" to "test#index"
    And I perform a request to "http://example.com:123/test/index?param=value"
    Then I should receive the following Airbrake notification:
      | component     | test                                          |
      | action        | index                                         |
      | error message | RuntimeError: some message                    |
      | error class   | RuntimeError                                  |
      | parameters    | credit_card_number: [FILTERED]                |
      | url           | http://example.com:123/test/index?param=value |

  Scenario: Filtering session in a controller
    When I generate a new Rails application
    And I configure the Airbrake shim
    And I configure my application to require the "airbrake" gem
    And I run the airbrake generator with "-k myapikey"
    When I configure the notifier to use the following configuration lines:
      """
      config.api_key = "myapikey"
      config.params_filters << "secret"
      """
    And I define a response for "TestController#index":
      """
      session["secret"] = "blue42"
      raise RuntimeError, "some message"
      """
    And I route "/test/index" to "test#index"
    And I perform a request to "http://example.com:123/test/index?param=value"
    Then I should receive the following Airbrake notification:
      | component     | test                                          |
      | action        | index                                         |
      | error message | RuntimeError: some message                    |
      | error class   | RuntimeError                                  |
      | session       | secret: [FILTERED]                            |
      | url           | http://example.com:123/test/index?param=value |

  Scenario: Filtering session and params based on Rails parameter filters
    When I generate a new Rails application
    And I configure the Airbrake shim
    And I configure my application to require the "airbrake" gem
    And I run the airbrake generator with "-k myapikey"
    And I configure the application to filter parameter "secret"
    And I define a response for "TestController#index":
      """
      params["secret"] = "red23"
      session["secret"] = "blue42"
      raise RuntimeError, "some message"
      """
    And I route "/test/index" to "test#index"
    And I perform a request to "http://example.com:123/test/index?param=value"
    Then I should receive the following Airbrake notification:
      | component     | test                                          |
      | action        | index                                         |
      | error message | RuntimeError: some message                    |
      | error class   | RuntimeError                                  |
      | params        | secret: [FILTERED]                            |
      | session       | secret: [FILTERED]                            |
      | url           | http://example.com:123/test/index?param=value |

  Scenario: Notify airbrake within the controller
    When I generate a new Rails application
    And I configure the Airbrake shim
    And I configure my application to require the "airbrake" gem
    And I run the airbrake generator with "-k myapikey"
    And I define a response for "TestController#index":
      """
      session[:value] = "test"
      notify_airbrake(RuntimeError.new("some message"))
      render :nothing => true
      """
    And I route "/test/index" to "test#index"
    And I perform a request to "http://example.com:123/test/index?param=value"
    Then I should receive the following Airbrake notification:
      | component     | test                                          |
      | action        | index                                         |
      | error message | RuntimeError: some message                    |
      | error class   | RuntimeError                                  |
      | session       | value: test                                   |
      | parameters    | param: value                                  |
      | url           | http://example.com:123/test/index?param=value |
