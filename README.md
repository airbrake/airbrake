Airbrake
========

[![Build Status](https://github.com/airbrake/airbrake/workflows/airbrake/badge.svg)](https://github.com/airbrake/airbrake/actions)
[![Code Climate](https://codeclimate.com/github/airbrake/airbrake.svg)](https://codeclimate.com/github/airbrake/airbrake)
[![Gem Version](https://badge.fury.io/rb/airbrake.svg)](http://badge.fury.io/rb/airbrake)
[![Documentation Status](http://inch-ci.org/github/airbrake/airbrake.svg?branch=master)](http://inch-ci.org/github/airbrake/airbrake)
[![Downloads](https://img.shields.io/gem/dt/airbrake.svg?style=flat)](https://rubygems.org/gems/airbrake)
[![Reviewed by Hound](https://img.shields.io/badge/Reviewed_by-Hound-8E64B0.svg)](https://houndci.com)

<p align="center">
  <img src="https://airbrake-github-assets.s3.amazonaws.com/brand/airbrake-full-logo.png" width="200">
</p>

* [Airbrake README](https://github.com/airbrake/airbrake)
* [Airbrake Ruby README](https://github.com/airbrake/airbrake-ruby)
* [YARD API documentation](http://www.rubydoc.info/gems/airbrake-ruby)

Introduction
------------

[Airbrake][airbrake.io] is an online tool that provides robust exception
tracking in any of your Ruby applications. In doing so, it allows you to easily
review errors, tie an error to an individual piece of code, and trace the cause
back to recent changes. The Airbrake dashboard provides easy categorization,
searching, and prioritization of exceptions so that when errors occur, your team
can quickly determine the root cause.

Key features
------------

![The Airbrake Dashboard][dashboard]

This library is built on top of [Airbrake Ruby][airbrake-ruby]. The difference
between _Airbrake_ and _Airbrake Ruby_ is that the `airbrake` gem is just a
collection of integrations with frameworks or other libraries. The
`airbrake-ruby` gem is the core library that performs exception sending and
other heavy lifting.

Normally, you just need to depend on this gem, select the integration you are
interested in and follow the instructions for it. If you develop a pure
frameworkless Ruby application or embed Ruby and don't need any of the listed
integrations, you can depend on the `airbrake-ruby` gem and ignore this gem
entirely.

The list of integrations that are available in this gem includes:

* [Heroku support][heroku-docs] (as an [add-on][heroku-addon])
* Web frameworks
  * Rails<sup>[[link](#rails)]</sup>
  * Sinatra<sup>[[link](#sinatra)]</sup>
  * Rack applications<sup>[[link](#rack)]</sup>
* Job processing libraries
  * ActiveJob<sup>[[link](#activejob)]</sup>
  * Resque<sup>[[link](#resque)]</sup>
  * Sidekiq<sup>[[link](#sidekiq)]</sup>
  * DelayedJob<sup>[[link](#delayedjob)]</sup>
  * Shoryuken<sup>[[link](#shoryuken)]</sup>
  * Sneakers<sup>[[link](#sneakers)]</sup>
* Other libraries
  * ActionCable<sup>[[link](#actioncable)]</sup>
  * Rake<sup>[[link](#rake)]</sup>
  * Logger<sup>[[link](#logger)]</sup>
* Plain Ruby scripts<sup>[[link](#plain-ruby-scripts)]</sup>

Deployment tracking:

* Using Capistrano<sup>[[link](#capistrano)]</sup>
* Using the Rake task<sup>[[link](#rake-task)]</sup>

Installation
------------

### Bundler

Add the Airbrake gem to your Gemfile:

```ruby
gem 'airbrake'
```

### Manual

Invoke the following command from your terminal:

```bash
gem install airbrake
```

Configuration
-------------

### Rails

#### Integration

To integrate Airbrake with your Rails application, you need to know your
[project id and project key][project-idkey]. Set `AIRBRAKE_PROJECT_ID` &
`AIRBRAKE_PROJECT_KEY` environment variables with your project's values and
generate the Airbrake config:

```bash
export AIRBRAKE_PROJECT_ID=<PROJECT ID>
export AIRBRAKE_PROJECT_KEY=<PROJECT KEY>

rails g airbrake
```

[Heroku add-on][heroku-addon] users can omit specifying the key and the
id. Heroku add-on's environment variables will be used ([Heroku add-on
docs][heroku-docs]):

```bash
rails g airbrake
```

This command will generate the Airbrake configuration file under
`config/initializers/airbrake.rb`. Make sure that this file is checked into your
version control system. This is enough to start Airbraking.

In order to configure the library according to your needs, open up the file and
edit it. [The full list of supported configuration options][config] is available
online.

To test the integration, invoke a special Rake task that we provide:

```ruby
rake airbrake:test
```

In case of success, a test exception should appear in your dashboard.

#### The notify_airbrake controller helpers

The Airbrake gem defines two helper methods available inside Rails controllers:
`#notify_airbrake` and `#notify_airbrake_sync`. If you want to notify Airbrake
from your controllers manually, it's usually a good idea to prefer them over
[`Airbrake.notify`][airbrake-notify], because they automatically add
information from the Rack environment to notices. `#notify_airbrake` is
asynchronous, while `#notify_airbrake_sync` is synchronous (waits for responses
from the server and returns them). The list of accepted arguments is identical
to `Airbrake.notify`.

#### Additional features: user reporting, sophisticated API

The library sends all uncaught exceptions automatically, attaching the maximum
possible amount information that can help you to debug errors. The Airbrake gem
is capable of reporting information about the currently logged in user (id,
email, username, etc.), if you use an authentication library such as Devise. The
library also provides a special API for manual error
reporting. [The description of the API][airbrake-api] is available online.

#### Automatic integration with Rake tasks and Rails runner

Additionally, the Rails integration offers automatic exception reporting in any
Rake tasks<sup>[[link](#rake)]</sup> and [Rails runner][rails-runner].

#### Integration with filter_parameters

If you want to reuse `Rails.application.config.filter_parameters` in Airbrake
you can configure your notifier the following way:

```rb
# config/initializers/airbrake.rb
Airbrake.configure do |c|
  c.blocklist_keys = Rails.application.config.filter_parameters
end
```

There are a few important details:

1. You must load `filter_parameter_logging.rb` before the Airbrake config
2. If you use Lambdas to configure `filter_parameters`, you need to convert them
   to Procs. Otherwise you will get `ArgumentError`
3. If you use Procs to configure `filter_parameters`, the procs must return an
   Array of keys compatible with the Airbrake allowlist/blocklist option
   (String, Symbol, Regexp)

Consult the
[example application](https://github.com/kyrylo/airbrake-ruby-issue108), which
was created to show how to configure `filter_parameters`.

##### filter_parameters dot notation warning

The dot notation introduced in [rails/pull/13897][rails-13897] for
`filter_parameters` (e.g. a key like `credit_card.code`) is unsupported for
performance reasons. Instead, simply specify the `code` key. If you have a
strong opinion on this, leave a comment in
the [dedicated issue][rails-sub-keys].

##### Logging

In new Rails apps, by default, all the Airbrake logs are written into
`log/airbrake.log`. In older versions we used to write to wherever
`Rails.logger` writes. If you wish to upgrade your app to the new behaviour,
please configure your logger the following way:

```ruby
c.logger = Airbrake::Rails.logger
```

### Sinatra

To use Airbrake with Sinatra, simply `require` the gem, [configure][config] it
and `use` our Rack middleware.

```ruby
# myapp.rb
require 'sinatra/base'
require 'airbrake'

Airbrake.configure do |c|
  c.project_id = 113743
  c.project_key = 'fd04e13d806a90f96614ad8e529b2822'

  # Display debug output.
  c.logger.level = Logger::DEBUG
end

class MyApp < Sinatra::Base
  use Airbrake::Rack::Middleware

  get('/') { 1/0 }
end

run MyApp.run!
```

To run the app, add a file called `config.ru` to the same directory and invoke
`rackup` from your console.

```ruby
# config.ru
require_relative 'myapp'
```

That's all! Now you can send a test request to `localhost:9292` and check your
project's dashboard for a new error.

```bash
curl localhost:9292
```

### Rack

To send exceptions to Airbrake from any Rack application, simply `use` our Rack
middleware, and [configure][config] the notifier.

```ruby
require 'airbrake'
require 'airbrake/rack'

Airbrake.configure do |c|
  c.project_id = 113743
  c.project_key = 'fd04e13d806a90f96614ad8e529b2822'
end

use Airbrake::Rack::Middleware
```

**Note:** be aware that by default the library doesn't filter any parameters,
including user passwords. To filter out passwords
[add a filter](https://github.com/airbrake/airbrake-ruby#airbrakeadd_filter).

#### Appending information from Rack requests

If you want to append additional information from web requests (such as HTTP
headers), define a special filter such as:

```ruby
Airbrake.add_filter do |notice|
  next unless (request = notice.stash[:rack_request])
  notice[:params][:remoteIp] = request.env['REMOTE_IP']
end
```

The `notice` object carries a real `Rack::Request` object in
its [stash](https://github.com/airbrake/airbrake-ruby#noticestash--noticestash).
Rack requests will always be accessible through the `:rack_request` stash key.

#### Optional Rack request filters

The library comes with optional predefined builders listed below.

##### RequestBodyFilter

`RequestBodyFilter` appends Rack request body to the notice. It accepts a
`length` argument, which tells the filter how many bytes to read from the body.

By default, up to 4096 bytes is read:

```ruby
Airbrake.add_filter(Airbrake::Rack::RequestBodyFilter.new)
```

You can redefine how many bytes to read by passing an Integer argument to the
filter. For example, read up to 512 bytes:

```ruby
Airbrake.add_filter(Airbrake::Rack::RequestBodyFilter.new(512))
```

#### Sending custom route breakdown performance

##### Arbitrary code performance instrumentation

For every route in your app Airbrake collects performance breakdown
statistics. If you need to monitor a specific operation, you can capture your
own breakdown:

```ruby
def index
  Airbrake::Rack.capture_timing('operation name') do
    call_operation(...)
  end

  call_other_operation
end
```

That will benchmark `call_operation` and send performance information to
Airbrake, to the corresponding route (under the 'operation name' label).

##### Method performance instrumentation

Alternatively, you can measure performance of a specific method:

```ruby
class UsersController
  extend Airbrake::Rack::Instrumentable

  def index
    call_operation(...)
  end
  airbrake_capture_timing :index
end
```

Similarly to the previous example, performance information of the `index` method
will be sent to Airbrake.

### Sidekiq

We support Sidekiq v2+. The configurations steps for them are identical. Simply
`require` our integration and you're done:

```ruby
require 'airbrake/sidekiq'
```

If you required Sidekiq before Airbrake, then you don't even have to `require`
anything manually and it should just work out-of-box.


#### Airbrake::Sidekiq::RetryableJobsFilter

By default, Airbrake notifies of all errors, including reoccurring errors during
a retry attempt. To filter out these errors and only get notified when Sidekiq
has exhausted its retries you can add the `RetryableJobsFilter`:

```ruby
Airbrake.add_filter(Airbrake::Sidekiq::RetryableJobsFilter.new)
```

The filter accepts an optional `max_retries` parameter. When set, it configures
the amount of allowed job retries that won't trigger an Airbrake notification.
Normally, this parameter is configured by the job itself but this setting takes
the highest precedence and forces the value upon all jobs, so be careful when
you use it. By default, it's not set.

```ruby
Airbrake.add_filter(
  Airbrake::Sidekiq::RetryableJobsFilter.new(max_retries: 10)
)
```

### ActiveJob

No additional configuration is needed. Simply ensure that you have configured
your Airbrake notifier with your queue adapter.

### Resque

Simply `require` the Resque integration:

```ruby
require 'airbrake/resque'
```

#### Integrating with Rails applications

If you're working with Resque in the context of a Rails application, create a
new initializer in `config/initializers/resque.rb` with the following content:

```ruby
# config/initializers/resque.rb
require 'airbrake/resque'
Resque::Failure.backend = Resque::Failure::Airbrake
```

Now you're all set.

#### General integration

Any Ruby app using Resque can be integrated with Airbrake. If you can require
the Airbrake gem *after* Resque, then there's no need to require
`airbrake/resque` anymore:

```ruby
require 'resque'
require 'airbrake'

Resque::Failure.backend = Resque::Failure::Airbrake
```

If you're unsure, just configure it similar to the Rails approach. If you use
multiple backends, then continue reading the needed configuration steps in
[the Resque wiki][resque-wiki] (it's fairly straightforward).

### DelayedJob

Simply `require` our integration and you're done:

```ruby
require 'airbrake/delayed_job'
```

If you required DelayedJob before Airbrake, then you don't even have to `require`
anything manually and it should just work out-of-box.

### Shoryuken

Simply `require` our integration and you're done:

```ruby
require 'airbrake/shoryuken'
```

If you required Shoryuken before Airbrake, then you don't even have to `require`
anything manually and it should just work out-of-box.

### Sneakers

Simply `require` our integration and you're done:

```ruby
require 'airbrake/sneakers'
```

If you required Sneakers before Airbrake, then you don't even have to `require`
anything manually and it should just work out-of-box.

### ActionCable

The ActionCable integration sends errors occurring in ActionCable actions and
subscribed/unsubscribed events. If you use Rails with ActionCable, there's
nothing to do, it's already loaded. If you use ActionCable outside Rails, simply
require it:

```ruby
require 'airbrake/rails/action_cable'
```

### Rake

Airbrake offers Rake tasks integration, which is used by our Rails
integration<sup>[[link](#rails)]</sup>. To integrate Airbrake in any project,
just `require` the gem in your `Rakefile`, if it hasn't been required and
[configure][config] the notifier.

```ruby
# Rakefile
require 'airbrake'

Airbrake.configure do |c|
  c.project_id = 113743
  c.project_key = 'fd04e13d806a90f96614ad8e529b2822'
end

task :foo do
  1/0
end
```

### Logger

If you want to convert your log messages to Airbrake errors, you can use our
integration with Ruby's `Logger` class from stdlib. All you need to do is to
wrap your logger in Airbrake's decorator class:

```ruby
require 'airbrake/logger'

# Create a normal logger
logger = Logger.new($stdout)

# Wrap it
logger = Airbrake::AirbrakeLogger.new(logger)
```

Now you can use the `logger` object exactly the same way you use it. For
example, calling `fatal` on it will both log your message and send it to the
Airbrake dashboard:

```
logger.fatal('oops')
```

The Logger class will attempt to utilize the default Airbrake notifier to
deliver messages. It's possible to redefine it via `#airbrake_notifier`:

```ruby
# Assign your own notifier.
logger.airbrake_notifier = Airbrake::NoticeNotifier.new
```

#### Airbrake severity level

In order to reduce the noise from the Logger integration it's possible to
configure Airbrake severity level. For example, if you want to send only fatal
messages from Logger, then configure it as follows:

```ruby
# Send only fatal messages to Airbrake, ignore anything below this level.
logger.airbrake_level = Logger::FATAL
```

By default, `airbrake_level` is set to `Logger::WARN`, which means it
sends warnings, errors and fatal error messages to Airbrake.

#### Configuring Airbrake logger integration with a Rails application

In order to configure a production logger with Airbrake integration, simply
overwrite `Rails.logger` with a wrapped logger in an `after_initialize`
callback:

```ruby
# config/environments/production.rb
config.after_initialize do
  # Standard logger with Airbrake integration:
  # https://github.com/airbrake/airbrake#logger
  Rails.logger = Airbrake::AirbrakeLogger.new(Rails.logger)
end
```

#### Configuring Rails APM SQL query stats when using Rails engines

By default, the library collects Rails SQL performance stats. For standard Rails
apps no extra configuration is needed. However if your app uses [Rails
engines](https://guides.rubyonrails.org/engines.html), you need to take an
additional step to make sure that the file and line information is present for
queries being executed in the engine code.

Specifically, you need to make sure that your
[`Rails.backtrace_cleaner`](https://api.rubyonrails.org/classes/ActiveSupport/BacktraceCleaner.html)
has a silencer that doesn't silence engine code (will be silenced by
default). For example, if your engine is called `blorgh` and its main directory
is in the root of your project, you need to extend the default silencer provided
with Rails and add the path to your engine:

```rb
# config/initializers/backtrace_silencers.rb

# Delete default silencer(s).
Rails.backtrace_cleaner.remove_silencers!

# Define custom silencer, which adds support for the "blorgh" engine
Rails.backtrace_cleaner.add_silencer do |line|
  app_dirs_pattern = %r{\A/?(app|config|lib|test|blorgh|\(\w*\))}
  !app_dirs_pattern.match?(line)
end
```

### Plain Ruby scripts

Airbrake supports _any_ type of Ruby applications including plain Ruby scripts.
If you want to integrate your script with Airbrake, you don't have to use this
gem. The [Airbrake Ruby][airbrake-ruby] gem provides all the needed tooling.

Deploy tracking
---------------

By notifying Airbrake of your application deployments, all errors are resolved
when a deploy occurs, so that you'll be notified again about any errors that
reoccur after a deployment. Additionally, it's possible to review the errors in
Airbrake that occurred before and after a deploy.

There are several ways to integrate deployment tracking with your application,
that are described below.

### Capistrano

The library supports Capistrano v2 and Capistrano v3. In order to configure
deploy tracking with Capistrano simply `require` our integration from your
Capfile:

```ruby
# Capfile
require 'airbrake/capistrano'
```

If you use Capistrano 3, define the `after :finished` hook, which executes the
deploy notification task (Capistrano 2 doesn't require this step).

```ruby
# config/deploy.rb
namespace :deploy do
  after :finished, 'airbrake:deploy'
end
```

If you version your application, you can set the `:app_version` variable in
`config/deploy.rb`, so that information will be attached to your deploy.

```ruby
# config/deploy.rb
set :app_version, '1.2.3'
```

### Rake task

A Rake task can accept several arguments shown in the table below:

| Key       | Required | Default   | Example |
------------|----------|-----------|----------
ENVIRONMENT | No       | Rails.env | production
USERNAME    | No       | nil       | john
REPOSITORY  | No       | nil       | https://github.com/airbrake/airbrake
REVISION    | No       | nil       | 38748467ea579e7ae64f7815452307c9d05e05c5
VERSION     | No       | nil       | v2.0

#### In Rails

Simply invoke `rake airbrake:deploy` and pass needed arguments:

```bash
rake airbrake:deploy USERNAME=john ENVIRONMENT=production REVISION=38748467 REPOSITORY=https://github.com/airbrake/airbrake
```

#### Anywhere

Make sure to `require` the library Rake integration in your Rakefile.

```ruby
# Rakefile
require 'airbrake/rake/tasks'
```

Then, invoke it like shown in the example for Rails.

Supported Rubies
----------------

* CRuby >= 2.5.0
* JRuby >= 9k

Contact
-------

In case you have a problem, question or a bug report, feel free to:

* [file an issue][issues]
* [send us an email](mailto:support@airbrake.io)
* [tweet at us][twitter]
* chat with us (visit [airbrake.io][airbrake.io] and click on the round orange
  button in the bottom right corner)

License
-------

The project uses the MIT License. See LICENSE.md for details.

Development & testing
---------------------

In order to run the test suite, first of all, clone the repo, and install
dependencies with Bundler.

```bash
git clone https://github.com/airbrake/airbrake.git
cd airbrake
bundle
```

Next, run unit tests.

```bash
bundle exec rake
```

In order to test integrations with frameworks and other libraries, install their
dependencies with help of the following command:

```bash
bundle exec appraisal install
```

To run integration tests for a specific framework, use the `appraisal` command.

```bash
bundle exec appraisal rails-4.2 rake spec:integration:rails
bundle exec appraisal sinatra rake spec:integration:sinatra
```

Pro tip: [GitHub Actions config](/.github/workflows/test.yml) has the list of
all the integration tests and commands to invoke them.

[airbrake.io]: https://airbrake.io
[airbrake-ruby]: https://github.com/airbrake/airbrake-ruby
[issues]: https://github.com/airbrake/airbrake/issues
[twitter]: https://twitter.com/airbrake
[project-idkey]: https://github.com/airbrake/airbrake-ruby#project_id--project_key
[config]: https://github.com/airbrake/airbrake-ruby#config-options
[airbrake-api]: https://github.com/airbrake/airbrake-ruby#api
[rails-runner]: http://guides.rubyonrails.org/command_line.html#rails-runner
[resque-wiki]: https://github.com/resque/resque/wiki/Failure-Backends#using-multiple-failure-backends-at-once
[heroku-addon]: https://elements.heroku.com/addons/airbrake
[heroku-docs]: https://devcenter.heroku.com/articles/airbrake
[dashboard]: https://s3.amazonaws.com/airbrake-github-assets/airbrake/airbrake-dashboard.png
[rails-13897]: https://github.com/rails/rails/pull/13897
[rails-sub-keys]: https://github.com/airbrake/airbrake-ruby/issues/137
[airbrake-notify]: https://github.com/airbrake/airbrake-ruby#airbrakenotify
