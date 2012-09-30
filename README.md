Airbrake
========

This is the notifier gem for integrating apps with [Airbrake](http://airbrake.io).

When an uncaught exception occurs, Airbrake will POST the relevant data
to the Airbrake server specified in your environment.

Help
----

For help with using Airbrake and this notifier visit [our support site](http://help.airbrake.io).

For SSL verification see the [Resources](https://github.com/airbrake/airbrake/blob/master/resources/README.md).

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

### Upgrading From Earlier Versions of Airbrake

If you're currently using the plugin version (if you have a
vendor/plugins/hoptoad_notifier directory, you are), you'll need to perform a
few extra steps when upgrading to the gem version.

Add the airbrake gem to your app. In config/environment.rb:

    config.gem 'airbrake'

Remove the plugin:

    rm -rf vendor/plugins/hoptoad_notifier

Make sure the following line DOES NOT appear in your ApplicationController file:

    include HoptoadNotifier::Catcher

If it does, remove it.  The new catcher is automatically included by the gem
version of Airbrake.

Before running the airbrake generator, you need to find your project's API key.
Log in to your account at airbrake.io, and click on the "Projects" button.
Then, find your project in the list, and click on its name. In the left-hand
column, you'll see an "Edit this project" button. Click on that to get your
project's API key. If you accidentally use your personal API auth_token,
you will get API key not found errors, and exceptions will not be stored
by the Airbrake service.

Then from your project's RAILS_ROOT, run:

    rake gems:install
    script/generate airbrake --api-key your_key_here

Once installed, you should vendor the airbrake gem.

    rake gems:unpack GEM=airbrake

As always, if you choose not to vendor the airbrake gem, make sure
every server you deploy to has the gem installed or your application won't
start.

### Upgrading from Earlier Versions of the Hoptoad Gem (with config.gem)

If you're currently using the gem version of the hoptoad_notifier and have
a version of Rails that uses config.gem (in the 2.x series), there is
a step or two that you need to do to upgrade. First, you need to remove
the old version of the gem from vendor/gems:

    rm -rf vendor/gems/hoptoad_notifier-X.X.X

Then you must remove the hoptoad_notifier_tasks.rake file from lib:

    rm lib/tasks/hoptoad_notifier_tasks.rake

You can then continue to install normally. If you don't remove the rake file,
you will be unable to unpack this gem (Rails will think it's part of the
framework).



You can test that Airbrake is working in your production environment by using
this rake task (from RAILS_ROOT):

    rake airbrake:test

If everything is configured properly, that task will send a notice to Airbrake
which will be visible immediately.

### Removing hoptoad_notifier

in your ApplicationController, REMOVE this line:

    include HoptoadNotifiable

In your config/environment* files, remove all references to HoptoadNotifier

Remove the vendor/plugins/hoptoad_notifier directory.

### Remove hoptoad_notifier plugin

Remove the vendor/plugins/hoptoad_notifier directory before installing the gem, or run:

    script/plugin remove hoptoad_notifier

Non-rails apps using Bundler
----------------------------
There is an undocumented dependency in `activesupport` where the `i18n` gem is
required only if the core classes extensions are used (`active_support/core_ext`). 
This can lead to a confusing `LoadError` exception when using Airbrake. Until 
this is fixed in `activesupport` the workaround is to add `i18n` to the Gemfile 
for your Sinatra/Rack/pure ruby application:

    gem 'i18n'
    gem 'airbrake'

Rack
----

In order to use airbrake in a non-Rails rack app, just load
airbrake, configure your API key, and use the Airbrake::Rack
middleware:

    require 'rack'
    require 'airbrake'

    Airbrake.configure do |config|
      config.api_key = 'my_api_key'
    end

    app = Rack::Builder.app do
      run lambda { |env| raise "Rack down" }
    end
    
    use Airbrake::Rack
    run app

Sinatra
-------

Using airbrake in a Sinatra app is just like a Rack app:

    require 'sinatra'
    require 'airbrake'

    Airbrake.configure do |config|
      config.api_key = 'my api key'
    end

    use Airbrake::Rack

    get '/' do
      raise "Sinatra has left the building"
    end

Usage
-----

For the most part, Airbrake works for itself. 

It intercepts the exception middleware calls, sends notifications and continues the middleware call chain.

If you want to log arbitrary things which you've rescued yourself from a
controller, you can do something like this:

    ...
    rescue => ex
      notify_airbrake(ex)
      flash[:failure] = 'Encryptions could not be rerouted, try again.'
    end
    ...

The `#notify_airbrake` call will send the notice over to Airbrake for later
analysis. While in your controllers you use the `notify_airbrake` method, anywhere
else in your code, use `Airbrake.notify`.

To perform custom error processing after Airbrake has been notified, define the
instance method `#rescue_action_in_public_without_airbrake(exception)` in your
controller.

Rake Tasks
----------
Do you want Airbrake to report exceptions that happen inside a rake task?
    
    Airbrake.configure do |config|
      ...
      config.rescue_rake_exceptions = true
    end

Informing the User
------------------

The airbrake gem is capable of telling the user information about the error that just happened
via the user_information option. They can give this error number in bug reports, for example.
By default, if your 500.html contains the text

    <!-- AIRBRAKE ERROR -->

then that comment will be replaced with the text "Airbrake Error [errnum]". You can modify the text
of the informer by setting `config.user_information`. Airbrake will replace "{{ error_id }}" with the
ID of the error that is returned from Airbrake.

    Airbrake.configure do |config|
    ...
      config.user_information = "<p>Tell the devs that it was <strong>{{ error_id }}</strong>'s fault.</p>"
    end

You can also turn the middleware that handles this completely off by setting `config.user_information` to false.

Note that this feature is reading the error id from `env['airbrake.error_id']`. When the exception is caught
automatically in a controller, Airbrake sets that value. If you're, however, calling the Airbrake methods like
`Airbrake#notify` or `Airbrake#notify_or_ignore`, please make sure you set that value. So the proper way of calling the 
"manual" methods would be `env['airbrake.error_id'] = Airbrake.notify_or_ignore(...)`.

Current user information
------------------------
Airbrake provides information about the current logged in user, so you
can easily determine the user who experienced the error in your app.

It uses `current_user` and `current_member` to identify the
authenticated user, where `current_user` takes precendence.

If you use different naming, please add the following lines to your
controller:

    alias_method :current_duck, :current_user
    helper_method :current_duck

Voila! You'll get information about a duck that experienced a crash of
your app.

By default Airbrake collects the following attributes:
* id
* name
* username
* email

You can also customize attributes that will be collected

    Airbrake.configure do |config|
      ...
      # collect only user ids
      config.user_attributes = [:id] # ["id"] also works
    end

Asynchronous notifications with Airbrake
----------------------------------------
When your user experiences error using your application, it gets sent to
Airbrake server. This introduces a considerable latency in the response. 

Asynchronous notification sending deals with this problem. Airbrake uses 
[girl_friday](https://github.com/mperham/girl_friday) to achieve this
. (thanks Mike)

It's disabled by default and you can enable it in your Airbrake
configuration.

    Airbrake.configure do |config|
      ...
      config.async = true
    end

*Note that this feature is enabled with JRuby 1.6+, Rubinius 2.0+ and*
*Ruby 1.9+. It does not support Ruby 1.8 because of its poor threading*
*support.*

For implementing custom asynchronous notice delivery, send a block to `config.async`. It
receives `notice` param. Pass it to `Airbrake.sender.send_to_airbrake` method
to do actual delivery. In this way it's possible to move Airbrake notification
even in background worker(e.g. Resque or Sidekiq).

    # Thread-based asynchronous send
    Airbrake.configure do |config|
      ...
      config.async do |notice|
        Thread.new { Airbrake.sender.send_to_airbrake(notice) }
      end
    end

    # Resque-like configuration
    Airbrake.configure do |config|
      ...
      config.async do |notice|
        Resque.enqueue(AirbrakeDeliveryWorker, notice)
      end
    end

Tracking deployments in Airbrake
--------------------------------

Paying Airbrake plans support the ability to track deployments of your application in Airbrake.
By notifying Airbrake of your application deployments, all errors are resolved when a deploy occurs,
so that you'll be notified again about any errors that reoccur after a deployment.

Additionally, it's possible to review the errors in Airbrake that occurred before and after a deploy.

When Airbrake is installed as a gem, you need to add

    require 'airbrake/capistrano'

to your deploy.rb

If you don't use Capistrano, then you can use the following rake task from your
deployment process to notify Airbrake:

    rake airbrake:deploy TO=#{rails_env} REVISION=#{current_revision} REPO=#{repository} USER=#{local_user}

Going beyond exceptions
-----------------------

You can also pass a hash to `Airbrake.notify` method and store whatever you want,
not just an exception. And you can also use it anywhere, not just in
controllers:

    begin
      params = {
        # params that you pass to a method that can throw an exception
      }
      my_unpredicable_method(params)
    rescue => e
      Airbrake.notify_or_ignore(
        :error_class   => "Special Error",
        :error_message => "Special Error: #{e.message}",
        :parameters    => params
      )
    end

While in your controllers you use the `notify_airbrake` method, anywhere else in
your code, use `Airbrake.notify`. Airbrake will get all the information
about the error itself. As for a hash, these are the keys you should pass:

* `:error_class` - Use this to group similar errors together. When Airbrake catches an exception it sends the class name of that exception object.
* `:error_message` - This is the title of the error you see in the errors list. For exceptions it is "#{exception.class.name}: #{exception.message}"
* `:parameters` - While there are several ways to send additional data to Airbrake, passing a Hash as :parameters as in the example above is the most common use case. When Airbrake catches an exception in a controller, the actual HTTP client request parameters are sent using this key.

Airbrake merges the hash you pass with these default options:

    {
      :api_key       => Airbrake.api_key,
      :error_message => 'Notification',
      :backtrace     => caller,
      :parameters    => {},
      :session       => {}
    }

You can override any of those parameters.

### Sending shell environment variables when "Going beyond exceptions"

One common request we see is to send shell environment variables along with
manual exception notification.  We recommend sending them along with CGI data
or Rack environment (:cgi_data or :rack_env keys, respectively.)

See Airbrake::Notice#initialize in lib/airbrake/notice.rb for
more details.

Filtering
---------

You can specify a whitelist of errors that Airbrake will not report on. Use
this feature when you are so apathetic to certain errors that you don't want
them even logged.

This filter will only be applied to automatic notifications, not manual
notifications (when #notify is called directly).

Airbrake ignores the following exceptions by default:

    ActiveRecord::RecordNotFound
    ActionController::RoutingError
    ActionController::InvalidAuthenticityToken
    CGI::Session::CookieStore::TamperedWithCookie
    ActionController::UnknownAction
    AbstractController::ActionNotFound
    Mongoid::Errors::DocumentNotFound


To ignore errors in addition to those, specify their names in your Airbrake
configuration block.

    Airbrake.configure do |config|
      config.api_key      = '1234567890abcdef'
      config.ignore       << "ActiveRecord::IgnoreThisError"
    end

To ignore *only* certain errors (and override the defaults), use the #ignore_only attribute.

    Airbrake.configure do |config|
      config.api_key      = '1234567890abcdef'
      config.ignore_only  = ["ActiveRecord::IgnoreThisError"] # or [] to ignore no exceptions.
    end

To ignore certain user agents, add in the #ignore_user_agent attribute as a
string or regexp:

    Airbrake.configure do |config|
      config.api_key      = '1234567890abcdef'
      config.ignore_user_agent  << /Ignored/
      config.ignore_user_agent << 'IgnoredUserAgent'
    end

To ignore exceptions based on other conditions, use #ignore_by_filter:

    Airbrake.configure do |config|
      config.api_key      = '1234567890abcdef'
      config.ignore_by_filter do |exception_data|
        true if exception_data[:error_class] == "RuntimeError"
      end
    end

To replace sensitive information sent to the Airbrake service with [FILTERED] use #params_filters:

    Airbrake.configure do |config|
      config.api_key      = '1234567890abcdef'
      config.params_filters << "credit_card_number"
    end

Note that, when rescuing exceptions within an ActionController method,
airbrake will reuse filters specified by #filter_parameter_logging.

Testing
-------

When you run your tests, you might notice that the Airbrake service is recording
notices generated using #notify when you don't expect it to. You can
use code like this in your test_helper.rb or spec_helper.rb files to redefine
that method so those errors are not reported while running tests.

    module Airbrake
      def self.notify(exception, opts = {})
        # do nothing.
      end
    end

Proxy Support
-------------

The notifier supports using a proxy, if your server is not able to directly reach the Airbrake servers. To configure the proxy settings, added the following information to your Airbrake configuration block.

    Airbrake.configure do |config|
      config.proxy_host = proxy.host.com
      config.proxy_port = 4038
      config.proxy_user = foo # optional
      config.proxy_pass = bar # optional
      
Logging
------------

Airbrake uses the logger from your Rails application by default, presumably STDOUT. If you don't like Airbrake scribbling to your 
standard output, just pass another `Logger` instance inside your configuration:

    Airbrake.configure do |config|
      ...
      config.logger = Logger.new("path/to/your/log/file")
    end

Supported Rails versions
------------------------

See SUPPORTED_RAILS_VERSIONS for a list of official supported versions of
Rails.

Please open up a support ticket ( http://help.airbrake.io ) or submit a new github issue
if you're using a version of Rails that is listed above and the notifier is
not working properly.

Javascript Notifer
------------------

To automatically include the Javascript node on every page, use this helper method from your layouts:

    <%= airbrake_javascript_notifier %>

It's important to insert this very high in the markup, above all other javascript.  Example:

    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="utf8">
        <%= airbrake_javascript_notifier %>
        <!-- more javascript -->
      </head>
      <body>
        ...
      </body>
    </html>

This helper will automatically use the API key, host, and port specified in the configuration.

The Javascript notifier tends to send much more notifications than the base Rails project.
If you want to receive them into a separate Airbrake project, specify its
API key in the `js_api_key` option.

    config.js_api_key = 'another-projects-api-key'

To test the Javascript notifier in development environment, overwrite (temporarily) the development_environments option:

    Airbrake.configure do |config|
      # ...
      config.development_environments = []
    end

Development
-----------

See TESTING.md for instructions on how to run the tests.

Credits
-------

![thoughtbot](http://thoughtbot.com/images/tm/logo.png)

Airbrake is maintained and funded by [airbrake.io](http://airbrake.io)

Thank you to all [the contributors](https://github.com/airbrake/airbrake/contributors)!

The names and logos for Airbrake, thoughtbot are trademarks of their respective holders.

License
-------

Airbrake is Copyright © 2008-2012 Airbrake. It is free software, and may be redistributed under the terms specified in the MIT-LICENSE file.
