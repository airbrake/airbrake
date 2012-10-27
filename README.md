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

    gem "airbrake"

Then from your project's RAILS_ROOT, and in your development environment, run:

    bundle install
    rails generate airbrake --api-key your_key_here

That's it!

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


Supported Rails versions
------------------------

See **SUPPORTED_RAILS_VERSIONS** for a list of official supported versions of
Rails.

Airbrake wiki pages
------------------------
Our wiki contains a lot of additional information about Airbrake configuration. Please browse the wiki when finished reading this
README:

https://github.com/airbrake/airbrake/wiki

Development
-----------

See `TESTING.md` for instructions on how to run the tests.

Credits
-------

![thoughtbot](http://thoughtbot.com/images/tm/logo.png)
![airbrake](https://secure.gravatar.com/avatar/9b706b7832bea4e387a9956531c12a7f)

Airbrake is maintained and funded by [airbrake.io](http://airbrake.io).

Thank you to all [the contributors](https://github.com/airbrake/airbrake/contributors)!

The names and logos for Airbrake, thoughtbot are trademarks of their respective holders.

License
-------

Airbrake is Copyright © 2008-2012 Airbrake. It is free software, and may be redistributed under the terms specified in the MIT-LICENSE file.
