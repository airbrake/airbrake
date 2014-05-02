Airbrake
========

[![Circle CI](https://circleci.com/gh/airbrake/airbrake/tree/master.png?circle-token=66cb9cfc6d20f550a2dbde522f5f0f9f81bd653b)](https://circleci.com/gh/airbrake/airbrake)
[![Code Climate](https://codeclimate.com/github/airbrake/airbrake.png)](https://codeclimate.com/github/airbrake/airbrake)
[![Coverage Status](https://coveralls.io/repos/airbrake/airbrake/badge.png?branch=master)](https://coveralls.io/r/airbrake/airbrake?branch=master)
[![Dependency Status](https://gemnasium.com/airbrake/airbrake.png)](https://gemnasium.com/airbrake/airbrake)

<img src="http://f.cl.ly/items/3Q163w1r2K1J1b030k0g/ruby%2009.19.32.jpg" width=800px>

This is the notifier gem for integrating apps with [Airbrake](http://airbrake.io).

When an uncaught exception occurs, Airbrake will POST the relevant data
to the Airbrake server specified in your environment.

<img scr="http://f.cl.ly/items/142j0Z2u0R1Y2L0L3D26/ruby.jpg" width=800px;>

Help
----

For help with using Airbrake and this notifier visit [our support site](http://help.airbrake.io).

For **SSL** verification see the [Resources](https://github.com/airbrake/airbrake/blob/master/resources/README.md).

Rails Installation
------------------

### Rails 3.x/4.x

Add the airbrake gem to your Gemfile.  In Gemfile:

    gem 'airbrake'

Then from your project's RAILS_ROOT, and in your development environment, run:

    bundle install
    rails generate airbrake --api-key your_key_here

The generator creates a file under `config/initializers/airbrake.rb` configuring Airbrake with your API key. This file should be checked into your version control system so that it is deployed to your staging and production environments.

### Rails 2.x

Add the airbrake gem to your app. In config/environment.rb:

    config.gem 'airbrake'

or if you are using bundler:

    gem 'airbrake', :require => 'airbrake/rails'

Then from your project's RAILS_ROOT, and in your development environment, run:

    rake gems:install
    rake gems:unpack GEM=airbrake
    script/generate airbrake --api-key your_key_here

As always, if you choose not to vendor the airbrake gem, make sure
every server you deploy to has the gem installed or your application won't start.

The generator creates a file under `config/initializers/airbrake.rb` configuring Airbrake with your API key. This file should be checked into your version control system so that it is deployed to your staging and production environments.

Ignored exceptions
------------------------

Exceptions raised from Rails environments named **development**, **test** or **cucumber** will be ignored by default. 

You can clear the list of ignored environments with this setting:

    config.development_environments = []

List of ignored exception classes includes:
    
    ActiveRecord::RecordNotFound
    ActionController::RoutingError
    ActionController::InvalidAuthenticityToken
    CGI::Session::CookieStore::TamperedWithCookie
    ActionController::UnknownHttpMethod
    ActionController::UnknownAction
    AbstractController::ActionNotFound
    Mongoid::Errors::DocumentNotFound

You can alter this list with

    config.ignore_only = []
    
which will cause none of the exception classes to be ignored.

Check the [wiki](https://github.com/airbrake/airbrake/wiki/Customizing-your-airbrake.rb) for more customization options.

Supported frameworks
------------------------

See **[TESTED_AGAINST](https://github.com/airbrake/airbrake/blob/master/TESTED_AGAINST)** for a full list of frameworks and versions we test against.

Airbrake wiki pages
------------------------
Our wiki contains a lot of additional information about Airbrake configuration. Please browse the wiki when finished reading this
README:

https://github.com/airbrake/airbrake/wiki

Development
-----------

For running unit tests, you should run

    bundle
    bundle exec rake test:unit

If you wish to run the entire suite, which checks the different framework
integrations with cucumber, you should run the following commands

    bundle
    bundle exec rake appraisal:install
    bundle exec rake

We use [Appraisals](https://github.com/thoughtbot/appraisal) to run the integration 
tests.

Maintainers
-----------

Make sure all tests are passing before pushing the new version. Also, make sure integration
test is passing. You can run it with:

    ./script/integration_test.rb <api_key> <host>

After this is passing, change the version inside *lib/airbrake/version.rb* and
push the new version with Changeling:

    rake changeling:change

Credits
-------

![thoughtbot](https://secure.gravatar.com/avatar/a95a04df2dae60397c38c9bd04492c53)

Airbrake is maintained and funded by [airbrake.io](http://airbrake.io).

Thank you to all [the contributors](https://github.com/airbrake/airbrake/contributors)!

The names and logos for Airbrake, thoughtbot are trademarks of their respective holders.

License
-------

Airbrake is Copyright © 2008-2013 Airbrake. 
