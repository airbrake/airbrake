Airbrake on Heroku
==================

Send your application errors to our hosted service and reclaim your inbox.

1. Installing the Heroku add-on
----------------------------
To use Airbrake on Heroku, install the Airbrake add-on:

    $ heroku addons:add airbrake:developer # If you'd like another plan, specify that instead.
                                           # Check https://addons.heroku.com/airbrake for a full list of plans.

2. Including the Airbrake notifier in your application
--------------------------------------------------
After adding the Airbrake add-on, you will need to install and configure the Airbrake notifier.

Your application connects to Airbrake with an API key. On Heroku, this is automatically provided to your
application in `ENV['AIRBRAKE_API_KEY']`, so installation should be a snap!

### Rails 3.x

Add the airbrake and heroku gems to your Gemfile.  In Gemfile:

    gem 'airbrake'
    gem 'heroku'

Then from your project's RAILS_ROOT, run:

    $ bundle install
    $ script/rails generate airbrake --heroku

### Rails 2.x

Install the heroku gem if you haven't already:

    gem install heroku

Add the airbrake gem to your app. In config/environment.rb:

    config.gem 'airbrake'

Then from your project's RAILS_ROOT, run:

    $ rake gems:install
    $ rake gems:unpack GEM=airbrake
    $ script/generate airbrake --heroku

As always, if you choose not to vendor the airbrake gem, make sure
every server you deploy to has the gem installed or your application won't start.

### Rack applications

In order to use airbrake in a non-Rails rack app, just load the airbrake, configure your API key, and use the Airbrake::Rack middleware:

    require 'rubygems'
    require 'rack'
    require 'airbrake'

    Airbrake.configure do |config|
      config.api_key = `ENV['AIRBRAKE_API_KEY']`
    end

    app = Rack::Builder.app do
      use Airbrake::Rack
      run lambda { |env| raise "Rack down" }
    end

### Rails 1.x

For Rails 1.x, visit the [Airbrake's README on GitHub](http://github.com/airbrake/airbrake),
and be sure to use `ENV['AIRBRAKE_API_KEY']` where your API key is required in configuration code.

3. Configure your notification settings (important!)
---------------------------------------------------

Once you have included and configured the notifier in your application,
you will want to configure your notification settings.

This is important - without setting your email address, you won't receive notification emails.

Airbrake can deliver exception notifications to your email inbox.  To configure these delivery settings:

1. Visit your applications resources page, like [ http://api.heroku.com/myapps/my-great-app/resources ](http://api.heroku.com/myapps/my-great-app/resources).
2. Click the name of your Airbrake addon. (It may still be called Hoptoad.)
3. Click "Settings" to configure the Airbrake Add-on.

4. Optionally: Set up deploy notification
-----------------------------------------

If your Airbrake plan supports deploy notification, set it up for your Heroku application like this:

    rake airbrake:heroku:add_deploy_notification

This will install a Heroku [HTTP Deploy Hook](http://docs.heroku.com/deploy-hooks) to notify Airbrake of the deploy.

You can pass in additional information for the deploy hook, in the ENV. Here are the available parameters:
* `ENV["RAILS_ENV"]`         - Rails environment you're deploying to, if not set on Heroku
* `ENV["AIRBRAKE_API_KEY"]`  - API key if not saved on Heroku or in initializer
* `ENV["HEROKU_APP"]`        - app name if you have multiple Heroku apps
* `ENV["REPO"]`              - Github url of the repo you're deploying, set this if you're not using remote named "origin"

We will also set "username" and "revision" from Heroku variables.
