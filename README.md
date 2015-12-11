Airbrake
========

[![Build Status](https://circleci.com/gh/airbrake/airbrake-gem.png?circle-token=97d268fcbb02dacb817dbc01e91d119500c360f5&style=shield)](https://circleci.com/gh/airbrake/airbrake-gem)
[![semver]](http://semver.org)

<img src="http://f.cl.ly/items/3Q163w1r2K1J1b030k0g/ruby%2009.19.32.jpg" width=800px>

* [Airbrake README](https://github.com/airbrake/airbrake)
* [Airbrake Ruby README](https://github.com/airbrake/airbrake-ruby)
* [YARD API documentation](http://www.rubydoc.info/gems/airbrake-ruby)
* [**Migration guide from v4 to v5**][migration-guide]

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
* Other libraries
  * Rake<sup>[[link](#rake)]</sup>
* Plain Ruby scripts<sup>[[link](#plain-ruby-scripts)]</sup>

[Paying Airbrake plans][pricing] support the ability to track deployments of
your application in Airbrake. We offer several ways to track your deployments:

* Using Capistrano<sup>[[link](#capistrano)]</sup>
* Using the Rake task<sup>[[link](#rake-task)]</sup>

Installation
------------

### Bundler

Add the Airbrake gem to your Gemfile:

```ruby
gem 'airbrake', '~> 5.0.0.rc.1'
```

### Manual

Invoke the following command from your terminal:

```bash
gem install airbrake --pre
```

Configuration
-------------

### Rails

#### Airbrake v5 is already here (but we still support Airbrake v4)

If you are migrating from Airbrake v4, please [read our migration
guide][migration-guide].

Since the 5th major release of the Airbrake gem we support only Rails 3.2+ and
Ruby 1.9+. Don't worry, if you use older versions of Rails or Ruby, just
continue using them with Airbrake v4: we _still_ support it. However, v4 is
_feature frozen_. We accept only bugfixes.

In the meantime, consider upgrading to Airbrake v5, as you miss a lot of new
features, such as support for multiple Airbrake configurations inside one Rails
project (you can report to different Airbrake projects in the same Ruby
process), nested exceptions, multiple asynchronous workers support, JRuby's Java
exceptions and many more.

#### Integration

To integrate Airbrake with your Rails application, you need to know
your [project id and project key][project-idkey]. Invoke the following command
and replace `PROJECT_ID` and `PROJECT_KEY` with your values:

```bash
rails g airbrake PROJECT_ID PROJECT_KEY
```

[Heroku add-on][heroku-addon] users can omit specifying the key and the id and invoke
the command without arguments (Heroku add-on's environment variables will be
used) ([Heroku add-on docs][heroku-docs]):

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
`Airbrake.notify`, because they automatically add information from the Rack
environment to notices. `#notify_airbrake` is asynchronous (immediately returns
`nil`), while `#notify_airbrake_sync` is synchronous (waits for responses from
the server and returns them). The list of accepted arguments is identical to
`Airbrake.notify`.

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
middleware, and [configure][config] the default notifier.

```ruby
require 'airbrake'

Airbrake.configure do |c|
  c.project_id = 113743
  c.project_key = 'fd04e13d806a90f96614ad8e529b2822'
end

use Airbrake::Rack::Middleware
```

### Sidekiq

We support Sidekiq v2, v3 and v4. The configurations steps for them are
identical. Simply `require` our error handler and you're done:

```ruby
require 'airbrake/sidekiq/error_handler'
```

If you required Sidekiq before Airbrake, then you don't even have to `require`
anything manually and it should just work out-of-box.

### ActiveJob

No additional configuration is needed. Simply ensure that you have configured
your Airbrake notifier.

### Resque

Since Airbrake v5 the gem provides its own failure backend. The old way of
integrating Resque doesn't work. If you upgrade to Airbrake v5, just make sure
that you require `airbrake/resque/failure` instead of
`resque/failure/airbrake`. The rest remains the same.

#### Integrating with Rails applications

If you're working with Resque in the context of a Rails application, create a
new initializer in `config/initializers/resque.rb` with the following content:

```ruby
# config/initializers/resque.rb
require 'airbrake/resque/failure'
Redis::Failure.backend = Resque::Failure::Airbrake
```

That's all configuration.

#### General integration

Any Ruby app using Resque can be integrated with Airbrake. If you can require
the Airbrake gem *after* Resque, then there's no need to require
`airbrake/resque/failure` anymore:

```ruby
require 'resque'
require 'airbrake'

Redis::Failure.backend = Resque::Failure::Airbrake
```

If you're unsure, just configure it similar to the Rails approach. If you use
multiple backends, then continue reading the needed configuration steps in
[the Resque wiki][resque-wiki] (it's fairly straightforward).

### DelayedJob

Simply `require` our plugin and you're done:

```ruby
require 'airbrake/delayed_job/plugin'
```

If you required DelayedJob before Airbrake, then you don't even have to `require`
anything manually and it should just work out-of-box.

### Rake

Airbrake offers Rake tasks integration, which is used by our Rails
integration<sup>[[link](#rails)]</sup>.  To integrate Airbrake in any project,
just `require` the gem in your `Rakefile`, if it hasn't been required and
[configure][config] the default notifier.

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

### Plain Ruby scripts

Airbrake supports _any_ type of Ruby applications including plain Ruby scripts.
If you want to integrate your script with Airbrake, you don't have to use this
gem. The [Airbrake Ruby][airbrake-ruby] gem provides all the needed tooling.

Deploy tracking
---------------

Airbrake has the ability to track your deploys (available only for
[paid plans][pricing]).

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
require 'airbrake/capistrano/tasks'
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

* CRuby >= 1.9.2
* JRuby >= 1.9-mode
* Rubinius >= 2.2.10

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

Pro tip: [`circle.yml`](/circle.yml) has the list of all integration tests and
commands to invoke them.

[airbrake.io]: https://airbrake.io
[airbrake-ruby]: https://github.com/airbrake/airbrake-ruby
[issues]: https://github.com/airbrake/airbrake/issues
[twitter]: https://twitter.com/airbrake
[project-idkey]: https://github.com/airbrake/airbrake-ruby#project_id--project_key
[config]: https://github.com/airbrake/airbrake-ruby#config-options
[airbrake-api]: https://github.com/airbrake/airbrake-ruby#api
[rails-runner]: http://guides.rubyonrails.org/command_line.html#rails-runner
[resque-wiki]: https://github.com/resque/resque/wiki/Failure-Backends#using-multiple-failure-backends-at-once
[pricing]: https://airbrake.io/pricing
[heroku-addon]: https://elements.heroku.com/addons/airbrake
[heroku-docs]: https://devcenter.heroku.com/articles/airbrake
[semver]: https://img.shields.io/:semver-5.0.0.rc.1-brightgreen.svg?style=flat
[migration-guide]: docs/Migration_guide_from_v4_to_v5.md
