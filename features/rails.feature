Feature: Install the Gem in a Rails application

  Background:
    Given I successfully run `rails new rails_root -O --skip-gemfile`
    And I cd to "rails_root"

  Scenario: Use the gem without vendoring the gem in a Rails application
    When I configure the Airbrake shim
    And I run `rails generate airbrake -k myapikey -t`
    Then I should receive a Airbrake notification
    And I should see the Rails version

  Scenario: Configure the notifier by hand
    When I configure the Airbrake shim
    And I configure the notifier to use "myapikey" as an API key
    And I run `rails generate airbrake`
    Then I should receive a Airbrake notification

  Scenario: Configuration within initializer isn't overridden by Railtie
    When I configure the Airbrake shim
    And I run `rails generate airbrake -k myapikey -t`
    And I configure the notifier to use the following configuration lines:
      """
      config.api_key = "myapikey"
      config.project_root = "argle/bargle"
      """
    And I define a response for "TestController#index":
      """
      raise RuntimeError, "some message"
      """
    And I route "/test/index" to "test#index"
    And I perform a request to "http://example.com:123/test/index?param=value"
    Then I should receive a Airbrake notification

  Scenario: Try to install without an api key
    When I run `rails generate airbrake`
    Then I should see "Must pass --api-key or --heroku or create config/initializers/airbrake.rb"

  Scenario: Generator should support the --secure option
    When I run `rails generate airbrake -k myapikey --secure`
    Then my Airbrake configuration should contain the following line:
    """
    config.secure = true
    """

  Scenario: Configure and deploy using only installed gem
    When I run `capify .`
    And I configure the Airbrake shim
    And I run `rails generate airbrake -k myapikey -t`
    And I run `cap -T`
    Then I should see "airbrake:deploy"

  Scenario: Try to install when the airbrake plugin still exists
    When I install the "airbrake" plugin
    And I configure the Airbrake shim
    And I configure the notifier to use "myapikey" as an API key
    And I run `rails generate airbrake`
    Then I should see "You must first remove the airbrake plugin. Please run: script/plugin remove airbrake"

  Scenario: Rescue an exception in a controller
    When I configure the Airbrake shim
    And I run `rails generate airbrake -k myapikey -t`
    And I define a response for "TestController#index":
      """
      raise RuntimeError, "some message"
      """
    And I route "/test/index" to "test#index"
    And I perform a request to "http://example.com:123/test/index?param=value"
    Then I should receive a Airbrake notification

  Scenario: The gem should not be considered a framework gem
    When I configure the Airbrake shim
    And I run `rails generate airbrake -k myapikey -t`
    And I run `rake gems`
    Then I should see that "airbrake" is not considered a framework gem

  Scenario: The app uses Vlad instead of Capistrano
    When I configure the Airbrake shim
    And I run `touch config/deploy.rb`
    And I run `rm Capfile`
    And I run `rails generate airbrake -k myapikey`
    Then "config/deploy.rb" should not contain "capistrano"

  @wip
  Scenario: Support the Heroku addon in the generator
    When I configure the Airbrake shim
    And I run `rails generate airbrake -k myapikey -t`
    And I configure the Heroku shim with "myapikey"
    And I successfully run `rails generate airbrake --heroku`
    Then I should receive a Airbrake notification
    And I should see the Rails version
    And my Airbrake configuration should contain the following line:
      """
      config.api_key = ENV['HOPTOAD_API_KEY']
      """

  @wip
  Scenario: Support the --app option for the Heroku addon in the generator
    When I configure the Airbrake shim
    And I configure the Heroku shim with "myapikey" and multiple app support
    And I run `rails generate airbrake --heroku -a myapp -t`
    Then I should receive a Airbrake notification
    And I should see the Rails version
    And my Airbrake configuration should contain the following line:
      """
      config.api_key = ENV['HOPTOAD_API_KEY']
      """

  Scenario: Filtering parameters in a controller
    When I configure the Airbrake shim
    And I run `rails generate airbrake -k myapikey -t`
    When I configure the notifier to use the following configuration lines:
      """
      config.api_key = "myapikey"
      config.params_filters << "credit_card_number"
      config.params_filters << "secret"
      config.logger = Logger.new STDOUT
      """
    And I define a response for "TestController#index":
      """
      session["secret"] = "blue42"
      params[:credit_card_number] = "red23"
      raise RuntimeError, "some message"
      """
    And I route "/test/index" to "test#index"
    And I perform a request to "http://example.com:123/test/index?param=value" in the "production" environment
    Then I should receive a Airbrake notification
    And the Airbrake notification should not contain "red23"
    And the Airbrake notification should not contain "blue42"
    And the Airbrake notification should contain "FILTERED"

  Scenario: Filtering session and params based on Rails parameter filters
    When I configure the Airbrake shim
    And I run `rails generate airbrake -k myapikey -t`
    When I configure the notifier to use the following configuration lines:
      """
      config.api_key = "myapikey"
      config.logger = Logger.new STDOUT
      """
    And I configure the application to filter parameter "secret"
    And I define a response for "TestController#index":
      """
      params["secret"]  = "red23"
      session["secret"] = "blue42"
      raise RuntimeError, "some message"
      """
    And I route "/test/index" to "test#index"
    And I perform a request to "http://example.com:123/test/index" in the "production" environment
    Then I should receive a Airbrake notification
    And the Airbrake notification should not contain "red23"
    And the Airbrake notification should not contain "blue42"
    And the Airbrake notification should contain "FILTERED"

  Scenario: Filtering sensitive Rack variables
    When I configure the Airbrake shim
    And I run `rails generate airbrake -k myapikey -t`
    When I configure the notifier to use the following configuration lines:
      """
      config.logger = Logger.new STDOUT
      """
    And I define a response for "TestController#index":
      """
      raise RuntimeError
      """
    Then I should receive a Airbrake notification
    And the Airbrake notification should not contain any of the sensitive Rack variables

  Scenario: Notify airbrake within the controller
    When I configure the Airbrake shim
    And I run `rails generate airbrake -k myapikey -t`
    And I define a response for "TestController#index":
      """
      session[:value] = "unicorn"
      notify_airbrake(RuntimeError.new("some message"))
      render :nothing => true
      """
    And I route "/test/index" to "test#index"
    And I perform a request to "http://example.com:123/test/index?param=value" in the "production" environment
    Then I should receive a Airbrake notification
    And the Airbrake notification should contain "unicorn"

  Scenario: Reporting 404s should be disabled by default
    When I configure the Airbrake shim
    And I configure the notifier to use the following configuration lines:
      """
         config.api_key = "myapikey"
      """
    And I perform a request to "http://example.com:123/this/route/does/not/exist" in the "production" environment
    Then I should see "The page you were looking for doesn't exist."
    And I should not receive a Airbrake notification

  Scenario: Reporting 404s should work when configured properly
    When I configure the Airbrake shim
    And I run `rails generate airbrake -k myapikey -t`
    When I configure the notifier to use the following configuration lines:
      """
      config.ignore_only = []
      """
    And I perform a request to "http://example.com:123/this/route/does/not/exist" in the "production" environment
    Then I should see "The page you were looking for doesn't exist"
    And I should receive a Airbrake notification

  @wip
  Scenario: reporting over SSL with utf8 check should work
    When I configure the Airbrake shim
    And I run `rails generate airbrake -k myapikey -t`
    When I configure the notifier to use the following configuration lines:
      """
      config.secure = true
      """
    And I define a response for "TestController#index":
      """
      raise RuntimeError, "some message"
      """
    And I route "/test/index" to "test#index"
    And I perform a request to "http://example.com:123/test/index?utf8=✓"
    Then I should receive a Airbrake notification

  Scenario: It should also send the user details
    When I configure the Airbrake shim
    And I configure the notifier to use the following configuration lines:
      """
         config.api_key = "myapikey"
         config.logger = Logger.new STDOUT
      """
    And I define a response for "TestController#index":
      """
      raise RuntimeError, "some message"
      """
    And I route "/test/index" to "test#index"
    And I have set up authentication system in my app that uses "current_user"
    And I perform a request to "http://example.com:123/test/index" in the "production" environment
    Then I should receive a Airbrake notification
    And the Airbrake notification should contain user details
    When I have set up authentication system in my app that uses "current_member"
    And I perform a request to "http://example.com:123/test/index" in the "production" environment
    Then I should receive a Airbrake notification
    And the Airbrake notification should contain user details

  Scenario: It should also send custom user attributes
    When I configure the Airbrake shim
    And I configure the notifier to use the following configuration lines:
      """
         config.api_key = "myapikey"
         config.logger = Logger.new STDOUT
         config.user_attributes = [:id, :name, :email, :username]
      """
    And I define a response for "TestController#index":
      """
      raise RuntimeError, "some message"
      """
    And I route "/test/index" to "test#index"
    And I have set up authentication system in my app that uses "current_user"
    And I perform a request to "http://example.com:123/test/index" in the "production" environment
    Then I should receive a Airbrake notification
    And the Airbrake notification should contain the custom user details

  Scenario: It should warn the user that she's using unsupported attributes for
    current user
    When I configure the Airbrake shim
    And I configure the notifier to use the following configuration lines:
      """
         config.api_key = "myapikey"
         config.logger = Logger.new STDOUT
         config.user_attributes = [:id, :name, :email, :username, :shoe_size]
      """
    And I run `rails runner config/boot.rb`
    Then I should see "Unsupported user attribute: 'shoe_size'"
    And I should not see "Unsupported user attribute: 'id'"

  Scenario: It should log the notice when failure happens
    When Airbrake server is not responding
    And I configure the notifier to use the following configuration lines:
      """
        config.api_key = "myapikey"
        config.logger  = Logger.new STDOUT
      """
    And I define a response for "TestController#index":
      """
      raise RuntimeError, "some message"
      """
    And I route "/test/index" to "test#index"
    And I perform a request to "http://example.com:123/test/index?param=value" in the "production" environment
    Then I should see "Notice details:"
    And I should see "some message"

  Scenario: It should send the framework info
    When I configure the Airbrake shim
    And I configure the notifier to use the following configuration lines:
    """
       config.api_key = "myapikey"
       config.logger  = Logger.new STDOUT
    """
    And I define a response for "TestController#index":
      """
      raise RuntimeError, "some message"
      """
    And I route "/test/index" to "test#index"
    And I perform a request to "http://example.com:123/test/index" in the "production" environment
    Then I should receive a Airbrake notification
    And the Airbrake notification should contain the framework information

  Scenario: Middleware should be correctly placed
    When I list the application's middleware and save it into a file
    Then the Airbrake middleware should be placed correctly
