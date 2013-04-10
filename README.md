Airbrake
========

This is the notifier gem for integrating apps with [Airbrake](http://airbrake.io).

When an uncaught exception occurs, Airbrake will POST the relevant data
to the Airbrake server specified in your environment.

Help
----

For help with using Airbrake and this notifier visit [our support site](http://help.airbrake.io).

For **SSL** verification see the [Resources](https://github.com/airbrake/airbrake/blob/master/resources/README.md).

Rails Installation
------------------

### Rails 3.x

Add the airbrake gem to your Gemfile.  In Gemfile:

    gem 'airbrake'

Then from your project's RAILS_ROOT, and in your development environment, run:

    bundle install
    rails generate airbrake --api-key your_key_here

That's it!

The generator creates a file under `config/initializers/airbrake.rb` configuring Airbrake with your API key. This file should be checked into your version control system so that it is deployed to your staging and production environments.

The default behaviour of the gem is to only operate in Rails environments that are NOT **development**, **test** & **cucumber**. 

You can change this by altering this array:

    config.development_environments = ["development", "test", "cucumber", "custom"]

Set it to empty array and it will report errors on all environments.


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

We use [Appraisals](https://github.com/thoughtbot/appraisal) to run the tests.

To run the test suite on your machine, you need to run the following commands:

    bundle
    bundle exec rake appraisal:install

After this, you're ready to run the suite with:

    bundle exec rake

This will include cucumber features we use to fully test the integration.

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
