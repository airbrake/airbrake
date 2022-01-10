Airbrake Changelog
==================

### master

Breaking changes:

* Dropped support for Ruby 2.5
  ([#1208](https://github.com/airbrake/airbrake/issues/1208))

### [v12.0.0][v12.0.0] (September 22, 2021)

Breaking changes:

* Dropped support for Ruby 2.3
  ([#1180](https://github.com/airbrake/airbrake/issues/1180))
* Dropped support for Ruby 2.4
  ([#1180](https://github.com/airbrake/airbrake/issues/1180))

Maintenance:

* Bumped `airbrake-ruby` requirement to `~> 6.0`
  ([#1179](https://github.com/airbrake/airbrake/pull/1179))

Other changes:

* Rails generator no longer embeds project id & project key into the generated
  initializer file. Set environment variables instead.

  Before:

  ```sh
  % rails g airbrake PROJECT_ID PROJECT_KEY
  ```

  After:

  ```sh
  export AIRBRAKE_PROJECT_ID=<PROJECT ID>
  export AIRBRAKE_PROJECT_KEY=<PROJECT KEY>

  rails g airbrake
  ```

### [v11.0.3][v11.0.3] (May 13, 2021)

* Fixed `Sneakers` integration when 3rd party code monkey-patches
   `Sneakers::Worker#process_work`
   ([#1164](https://github.com/airbrake/airbrake/issues/1164))
* Fixed `ActionCable` integration when 3rd party code monkey-patches
   `ActionCable::Channel::Base#perform_action`
   ([#1165](https://github.com/airbrake/airbrake/issues/1165))
* Fixed `Resque` integration when 3rd party code monkey-patches
   `Resque::Job#perform`
   ([#1166](https://github.com/airbrake/airbrake/issues/1166))
* Fixed `Rake` integration when 3rd party code monkey-patches
   `Rake::Task#execute`
   ([#1167](https://github.com/airbrake/airbrake/issues/1167))

### [v11.0.2][v11.0.2] (May 12, 2021)

* Fixed `HTTP::Client` performance breakdown when 3rd party code monkey-patches
   `HTTP::Client#perform`
   ([#1162](https://github.com/airbrake/airbrake/issues/1162))

### [v11.0.1][v11.0.1] (October 20, 2020)

* Fixed `rake airbrake::deploy` crashing with ``NoMethodError: undefined method
  `level' for nil:NilClass`` when the `RAILS_LOG_TO_STDOUT` environment variable
  is set ([#1129](https://github.com/airbrake/airbrake/pull/1129))
* Bumped `airbrake-ruby` requirement to `~> 5.1`
  ([#1133](https://github.com/airbrake/airbrake/issues/1133))


### [v11.0.0][v11.0.0] (August 17, 2020)

Breaking changes:

* Dropped support for Rails v3.2
  ([#1118](https://github.com/airbrake/airbrake/pull/1118))
* Dropped support for Ruby 2.1
  ([#1119](https://github.com/airbrake/airbrake/pull/1119))
* Dropped support for Ruby 2.2
  ([#1120](https://github.com/airbrake/airbrake/pull/1120))

Bug fixes:

* Rails APM: fixed double slash in front of a route name when mounting engines
  at `/` ([#1111](https://github.com/airbrake/airbrake/pull/1111))
* Rails: fixed broken initialization for some apps due to the load order of
  initializers ([#1112](https://github.com/airbrake/airbrake/pull/1112))

Maintenance:

* Bumped airbrake-ruby requirement to `~> 5.0`
  ([#1068](https://github.com/airbrake/airbrake/issues/1068))

Features:

* Rails APM: made it possible to enable/disable APM at runtime
  ([#1112](https://github.com/airbrake/airbrake/pull/1112))

### [v10.1.0.rc.1][v10.1.0.rc.1] (July 14, 2020)

* Fixes `Airbrake::Sidekiq::RetryableJobsFilter` erroneously reporting retry
  attempts when it shouldn't
  ([#1103](https://github.com/airbrake/airbrake/pull/1103))
* Started depending on airbrake-ruby
  [v5.0.0.rc.1](https://github.com/airbrake/airbrake-ruby/releases/tag/v5.0.0.rc.1)

### [v10.0.5][v10.0.5] (June 17, 2020)

* Fixed deprecation warning about "connection_config" on Rails 6.1+
  ([#1098](https://github.com/airbrake/airbrake/issues/1098))
* Fixed the `blacklist_keys` deprecation warning in Rails generator
  ([#1099](https://github.com/airbrake/airbrake/issues/1099))

### [v10.0.4][v10.0.4] (May 21, 2020)

* Rails APM: fixed support for "catch-all" routes, which grouped all matching
  routes as one, instead of reporting those routes separately
  ([#1092](https://github.com/airbrake/airbrake/issues/1092))

### [v10.0.3][v10.0.3] (April 22, 2020)

* Rails APM: fixed wrong file/line/function for SQL queries if a query is
  executed by a Rails engine
  ([#1082](https://github.com/airbrake/airbrake/issues/1082))
* Fixed performance degradation of Delayed Job jobs
  ([#1084](https://github.com/airbrake/airbrake/issues/1084))

### [v10.0.2][v10.0.2] (March 31, 2020)

* ActiveJob: fix error reporting
  ([#1074](https://github.com/airbrake/airbrake/issues/1074))
* Fixed `Net::HTTP` performance breakdown when 3rd party code monkey-patches
  `Net::HTTP#request` ([#1078](https://github.com/airbrake/airbrake/issues/1078))

### [v10.0.1][v10.0.1] (January 29, 2020)

* Bumped airbrake-ruby requirement to `~> 4.13`
  ([#1068](https://github.com/airbrake/airbrake/issues/1068))
* Rails APM: fixed bug where `query_stats = false` would sometimes have no
  effect ([#1069](https://github.com/airbrake/airbrake/pull/1069))
* Sneakers: fixed ArgumentError occurring in the error handler on some versions
  ([#1065](https://github.com/airbrake/airbrake/pull/1065))
* Made all string literals frozen by default
  ([#1070](https://github.com/airbrake/airbrake/pull/1070))
* Rack: improved `Airbrake::Rack::Instrumentable#airbrake_capture_timing`
  ([#1066](https://github.com/airbrake/airbrake/pull/1066)):
    - added support for methods ending with punctuation (`?`, `!` & `=`)
    - added support for wrapping operator methods
    - fixed bug where captured method would lose its original visibility
    - improved support for Ruby 2.7, specifically method forwarding
    - added support for capturing `prepend`'ed methods

### [v10.0.0][v10.0.0] (January 8, 2020)

* Sidekiq: started sending job execution statistics
  ([#1040](https://github.com/airbrake/airbrake/issues/1040))
* Resque: started sending job execution statistics
  ([#1044](https://github.com/airbrake/airbrake/issues/1044))
* Sneakers: started sending job execution statistics
  ([#1047](https://github.com/airbrake/airbrake/issues/1047))
* DelayedJob: started sending job execution statistics
  ([#1046](https://github.com/airbrake/airbrake/issues/1046))
* Shoryuken: started sending job execution statistics
  ([#1055](https://github.com/airbrake/airbrake/issues/1055))
* ActiveJob: started sending job execution statistics
  ([#1056](https://github.com/airbrake/airbrake/issues/1056))
* Rack: fixed `context/userAddr` sometimes not reporting the actual client IP
  (but a proxy IP instead)
  ([#1042](https://github.com/airbrake/airbrake/issues/1042))
* Bumped airbrake-ruby requirement to `~> 4.12`
  ([#1058](https://github.com/airbrake/airbrake/issues/1058))
* Rails APM: fixed bug where engine routes would always point to root path (for
  example, `engine_name#/` instead of `engine_name#my_path`)
  ([#1059](https://github.com/airbrake/airbrake/issues/1059))
* Fixed deprecation warnings about `:start_time` & `:end_time` coming from
  `airbrake-ruby` ([#1060](https://github.com/airbrake/airbrake/issues/1060))

### [v9.5.5][v9.5.5] (December 2, 2019)

* Rails APM: fixed issue with engine links when the engine has an isolated
  namespace ([#1035](https://github.com/airbrake/airbrake/issues/1035))

### [v9.5.4][v9.5.4] (November 27, 2019)

* Rails APM: fixed bug when client sends a request that couldn't be tied to a
  certain route ([#1032](https://github.com/airbrake/airbrake/issues/1032))

### [v9.5.3][v9.5.3] (November 27, 2019)

* Fixed `uninitialized constant Airbrake::Rails::App`
  ([#1030](https://github.com/airbrake/airbrake/issues/1030))

### [v9.5.2][v9.5.2] (November 26, 2019)

* Rails: fixed engine support for routes which became broken since v9.5.1
  ([#1028](https://github.com/airbrake/airbrake/pull/1028))

### [v9.5.1][v9.5.1] (November 25, 2019)

* Rails: Stopped including the `after_commit` ActiveRecord patch for Rails
  versions above 4.2 (because they are irrelevant ant cause buggy behaviour)
  ([#1023](https://github.com/airbrake/airbrake/pull/1023))
* Rails: improved support for route aliases. Fixed bug where an aliased route
  would be reported as two separate routes. Now it is recognized as the same
  route ([#1026](https://github.com/airbrake/airbrake/pull/1026))

### [v9.5.0][v9.5.0] (October 23, 2019)

* Started depending on airbrake-ruby
  [v4.8.0](https://github.com/airbrake/airbrake-ruby/releases/tag/v4.8.0) and
  higher ([#1016](https://github.com/airbrake/airbrake/pull/1016))
  **This update enables `query_stats` by default.**

### [v9.4.5][v9.4.5] (October 3, 2019)

* Fixed duplicate APM data that we used to send in Rails apps for some
  controller actions ([#1013](https://github.com/airbrake/airbrake/pull/1013))
* Memory usage improvements
  ([#1012](https://github.com/airbrake/airbrake/pull/1012))
* Started depending on airbrake-ruby
  [v4.7.0](https://github.com/airbrake/airbrake-ruby/releases/tag/v4.7.0) and
  higher ([#1015](https://github.com/airbrake/airbrake/pull/1015))

### [v9.4.4][v9.4.4] (September 18, 2019)

* Fixed broken `bundle exec rake airbrake:deploy`
  ([#1003](https://github.com/airbrake/airbrake/pull/1003))
* Introduced `Airbrake::Rails.logger`, which replaces the old way of configuring
  Rails apps. The logging setup becomes as simple as
  ([#1003](https://github.com/airbrake/airbrake/pull/1003)):

  ```ruby
  c.logger = Airbrake::Rails.logger
  ```
* Exceptions occurring in `current_user` no longer crash the library
  ([#1007](https://github.com/airbrake/airbrake/pull/1007))
* Rails controller helpers started supporting the block argument for notifying
  ([#1010](https://github.com/airbrake/airbrake/pull/1010))

### [v9.4.3][v9.4.3] (August 8, 2019)

* Rails: report unauthorized requests properly. Instead of 0 HTTP code the
  library sends 401 now ([#997](https://github.com/airbrake/airbrake/pull/997))

### [v9.4.2][v9.4.2] (August 7, 2019)

* Rails: engine routes are now being marked with the engine name prefix
  ([#997](https://github.com/airbrake/airbrake/pull/997))

### [v9.4.1][v9.4.1] (August 5, 2019)

* Started depending on airbrake-ruby
  [v4.6.0](https://github.com/airbrake/airbrake-ruby/releases/tag/v4.6.0) and
  higher ([#995](https://github.com/airbrake/airbrake/pull/995))
* Disabled SQL query collection by default because it's in alpha
  ([#995](https://github.com/airbrake/airbrake/pull/995))

### [v9.4.0][v9.4.0] (July 29, 2019)

* Added the new `max_retries` optional parameter to
  `Airbrake::Sidekiq::RetryableJobsFilter`:

  ```ruby
  Airbrake::Sidekiq::RetryableJobsFilter.new(max_retries: 10)
  ```

  It configures the amount of allowed job retries that won't trigger an Airbrake
  notification. After it's exhausted, Airbrake will start sending errors again
  ([#979](https://github.com/airbrake/airbrake/pull/979))
* Rails: started logging to `airbrake.log` by default. This affects only new
  Rails apps. Apps that already use Airbrake have to update the logger manually
  (not mandatory). Please consult README for instructions
  ([#986](https://github.com/airbrake/airbrake/pull/986))
* Added support for `RAILS_LOG_TO_STDOUT`. This variable redirects all Airbrake
  logging to STDOUT, despite the configured logger
  ([#986](https://github.com/airbrake/airbrake/pull/986))

### [v9.3.0][v9.3.0] (June 25, 2019)

* Fixed `notice.stash[:rack_request]` not being attached for exceptions that are
  reported through Rack environment (such as `rack.exception`)
  ([#977](https://github.com/airbrake/airbrake/pull/977))
* Fixed `Sidekiq RetryableJobsFilter` when `job['retry_count']` is `nil` (which
  happens the first time a job fails)
  ([#980](https://github.com/airbrake/airbrake/pull/980))
* Started depending on airbrake-ruby
  [v4.5.0](https://github.com/airbrake/airbrake-ruby/releases/tag/v4.5.0) and
  higher ([#982](https://github.com/airbrake/airbrake/pull/982)).
  **IMPORTANT:** in this update we enabled `performance_stats` by default. If
  you wish to disable it, set `config.performance_stats = false`
  ([#485](https://github.com/airbrake/airbrake-ruby/pull/485))


### [v9.2.2][v9.2.2] (May 10, 2019)

* Rails: started attaching Rack request and User info to the metric object,
  which is accessible through performance hooks:

  ```ruby
  Airbrake.add_performance_filter do |metric|
    if metric.stash.key?(:user)
      # custom logic
    end
  end
  ```

### [v9.2.1][v9.2.1] (May 1, 2019)

* Added the ability to provide a custom optional label for
  `Airbrake::Rack::Instrumentable#airbrake_capture_timing`
  ([#968](https://github.com/airbrake/airbrake/pull/968))

### [v9.2.0][v9.2.0] (April 30, 2019)

* Rails: added support for Curb for HTTP performance breakdown
  ([#957](https://github.com/airbrake/airbrake/pull/957))
* Rails: added support for Excon for HTTP performance breakdown
  ([#958](https://github.com/airbrake/airbrake/pull/958))
* Rails: added support for http.rb for HTTP performance breakdown
  ([#959](https://github.com/airbrake/airbrake/pull/959))
* Rails: added support for HTTPClient for HTTP performance breakdown
  ([#960](https://github.com/airbrake/airbrake/pull/960))
* Rails: added support for Typhoeus for HTTP performance breakdown
  ([#961](https://github.com/airbrake/airbrake/pull/961))
* Added `Airbrake::Rack.capture_timing` and `Airbrake::Rack::Instrumentable` for
  manual performance measurements
  ([#965](https://github.com/airbrake/airbrake/pull/965))

### [v9.1.0][v9.1.0] (April 17, 2019)

* Rails: added HTTP performance breakdown (`Net::HTTP` support only)
  ([#955](https://github.com/airbrake/airbrake/pull/955))

### [v9.0.2][v9.0.2] (April 8, 2019)

* Delete `Airbrake::Rack.add_default_filters`
  ([#951](https://github.com/airbrake/airbrake/pull/951))

### [v9.0.1][v9.0.1] (April 4, 2019)

* Started treating `*/*` response type as `:html` in
  `ActionControllerPerformanceBreakdownSubscriber`
  ([#949](https://github.com/airbrake/airbrake/pull/949))

### [v9.0.0][v9.0.0] (March 29, 2019)

* Fixed `NoMethodError` in `route_filter.rb` on 404 in Sinatra apps
  ([#939](https://github.com/airbrake/airbrake/pull/939))
* Stopped loading Rails performance hooks for apps that don't use performance
  stats ([#942](https://github.com/airbrake/airbrake/pull/942))
* Stopped loading default Rack filters for Sinatra & Rack integrations (Rails is
  not affected). You must load them manually after you `configure` your notifier
  with help of `Airbrake::Rack.add_default_filters`. Please refer to the README
  ([#942](https://github.com/airbrake/airbrake/pull/942))
* Started depending on airbrake-ruby
  [v4.2.0](https://github.com/airbrake/airbrake-ruby/releases/tag/v4.2.0) and
  higher ([#946](https://github.com/airbrake/airbrake/pull/946))

### [v8.3.2][v8.3.2] (March 12, 2019)

* Fixed the Rails performance breakdown hook not maintaining performance
  precision ([#936](https://github.com/airbrake/airbrake/pull/936))
* Fix Rails performance breakdown not being sent if one of the groups is zero
  ([#935](https://github.com/airbrake/airbrake/pull/935))

### [v8.3.1][v8.3.1] (March 11, 2019)

* Fixes `TypeError` in the `ActionControllerPerformanceBreakdownSubscriber` when
  it tries to pass `nil` as a `db` or `view` value
  ([#932](https://github.com/airbrake/airbrake/pull/932))

### [v8.3.0][v8.3.0] (March 11, 2019)

* Added `ActionCable` integration
  ([#926](https://github.com/airbrake/airbrake/pull/926),
  [#896](https://github.com/airbrake/airbrake/pull/896))
* Added `ActionControllerPerformanceBreakdownSubscriber`
  ([#929](https://github.com/airbrake/airbrake/pull/929))
* Fixed broken Rails integration for apps that don't use ActiveRecord
  ([#924](https://github.com/airbrake/airbrake/pull/924))

### [v8.2.1][v8.2.1] (March 4, 2019)

* Fix `NoMethodError` in `ActiveRecordSubscriber` when a caller of SQL query
  cannot be defined ([#920](https://github.com/airbrake/airbrake/pull/920))

### [v8.2.0][v8.2.0] (March 4, 2019)

* Started depending on airbrake-ruby
  [v4.1.0](https://github.com/airbrake/airbrake-ruby/releases/tag/v4.1.0) and
  higher ([#915](https://github.com/airbrake/airbrake/pull/915))
* `ActiveRecordSubscriber` started attaching file/line/func information to
  queries ([#913](https://github.com/airbrake/airbrake/pull/913))

### [v8.1.4][v8.1.4] (February 19, 2019)

* Fixed `ActionControllerRouteSubscriber` trying to track routeless events,
  which results into a `NoMethodError`
  ([#907](https://github.com/airbrake/airbrake/pull/907))

### [v8.1.3][v8.1.3] (February 19, 2019)

* Fixed `can't add a new key into hash during iteration` coming from
  ActionControllerRouteSubscriber
  ([#905](https://github.com/airbrake/airbrake/pull/905))
* Fixed Logger integration not respecting level of the logger that is being
  wrapped ([#903](https://github.com/airbrake/airbrake/pull/903))

### [v8.1.2][v8.1.2] (February 14, 2019)

* Fixed performance stats not being sent
  ([#901](https://github.com/airbrake/airbrake/pull/901))

### [v8.1.1][v8.1.1] (February 14, 2019)

* Fixed `uninitialized constant Airbrake::Rack::Middleware::ActiveRecord` for
  apps that don't use ActiveRecord
  ([#899](https://github.com/airbrake/airbrake/pull/899))

### [v8.1.0][v8.1.0] (February 12, 2019)

* Fixed warning coming from our middleware when using with Rails 6
  ([#893](https://github.com/airbrake/airbrake/pull/893))
* Started depending on airbrake-ruby
  [v3.2](https://github.com/airbrake/airbrake-ruby/releases/tag/v3.2.3) and
  higher ([#897](https://github.com/airbrake/airbrake/pull/897))
* Started sending SQL queries to Airbrake
  ([#892](https://github.com/airbrake/airbrake/pull/892))

### [v8.0.1][v8.0.1] (January 23, 2019)

* Moved user extraction logic from `Airbrake::Rack::ContextFilter` to
  `Airbrake::Rack::UserFilter`. This allows you writing your own `UserFilter`
  implementation (if you are not satisfied with the default one): step 1 is to
  delete the default filter by means of
  [`Airbrake.delete_filter`](https://github.com/airbrake/airbrake-ruby/tree/v3.1.0#airbrakedelete_filter),
  step 2 is to `add_filter(BetterUserFilter.new)`
  ([#890](https://github.com/airbrake/airbrake/pull/890))

### [v8.0.0][v8.0.0] (January 16, 2019)

* Bumped minimum requirement for airbrake-ruby to
  [v3.0.0](https://github.com/airbrake/airbrake-ruby/releases/tag/v3.0.0)
  or higher ([#889](https://github.com/airbrake/airbrake/pull/889))

### [v8.0.0.rc.9][v8.0.0.rc.9] (December 3, 2018)

* Bumped minimum requirement for airbrake-ruby to
  [v3.0.0.rc.9](https://github.com/airbrake/airbrake-ruby/releases/tag/v3.0.0.rc.9)
  or higher ([#881](https://github.com/airbrake/airbrake/pull/881))

### [v8.0.0.rc.8][v8.0.0.rc.8] (November 21, 2018)

* Fixed bug when routes that raise exceptions would sometimes return 0 as their
  `status_code`. Such routes return 500 now
  ([#878](https://github.com/airbrake/airbrake/pull/878))

### [v8.0.0.rc.7][v8.0.0.rc.7] (November 16, 2018)

* Fixed route reporting for routes that raise
  errors([#876](https://github.com/airbrake/airbrake/pull/876))

### [v8.0.0.rc.6][v8.0.0.rc.6] (November 12, 2018)

* Updated Request API to support latest changes in Airbrake Ruby
  ([#874](https://github.com/airbrake/airbrake/pull/874))

### [v8.0.0.rc.5][v8.0.0.rc.5] (November 6, 2018)

* Started depending on
  ([airbrake-ruby-3.0.0.rc.5](https://github.com/airbrake/airbrake-ruby/releases/tag/v3.0.0.rc.5))

### [v8.0.0.rc.4][v8.0.0.rc.4] (November 6, 2018)

* Started depending on
  [airbrake-ruby-3.0.0.rc.4](https://github.com/airbrake/airbrake-ruby/releases/tag/v3.0.0.rc.4)
  ([#872](https://github.com/airbrake/airbrake/pull/872))

### [v8.0.0.rc.3][v8.0.0.rc.3] (November 6, 2018)

* Started depending on
  [airbrake-ruby-3.0.0.rc.3](https://github.com/airbrake/airbrake-ruby/releases/tag/v3.0.0.rc.3)
  ([#871](https://github.com/airbrake/airbrake/pull/871))

### [v8.0.0.rc.2][v8.0.0.rc.2] (October 30, 2018)

* Started depending on
  [airbrake-ruby-3.0.0.rc.2](https://github.com/airbrake/airbrake-ruby/releases/tag/v3.0.0.rc.2)
  ([#868](https://github.com/airbrake/airbrake/pull/868))

### [v7.5.0.pre.1][v7.5.0.pre.1] (October 26, 2018)

* Added support for route stats for Rails, Sinatra & Rack
  ([#866](https://github.com/airbrake/airbrake/pull/866))

### [v7.4.0][v7.4.0] (October 11, 2018)

* Started depending on
  [airbrake-ruby-2.12.0](https://github.com/airbrake/airbrake-ruby/releases/tag/v2.12.0)
  ([#861](https://github.com/airbrake/airbrake/pull/861))

### [v7.3.5][v7.3.5] (August 9, 2018)

* Fixed overwriting `notice[:params]` in the Rake and ActiveJob integrations
  ([#859](https://github.com/airbrake/airbrake/pull/859))

### [v7.3.4][v7.3.4] (June 14, 2018)

* Fixed SystemStackError in the Sneakers integration
  ([#852](https://github.com/airbrake/airbrake/pull/852))

### [v7.3.3][v7.3.3] (May 11, 2018)

* Fixed Resque failure when the first item in payload args is not a hash
  ([#846](https://github.com/airbrake/airbrake/pull/846))

### [v7.3.2][v7.3.2] (May 8, 2018)

* Fixed `can't modify frozen Hash` error when using the Rack/Rails integration
  along with `DependencyFilter` from airbrake-ruby
  ([#847](https://github.com/airbrake/airbrake/pull/847))

### [v7.3.1][v7.3.1] (May 4, 2018)

* Rack/Rails/Sinatra integrations started attaching their versions to
  `context/versions` (was `context/version`)
  ([#843](https://github.com/airbrake/airbrake/pull/843))

### [v7.3.0][v7.3.0] (April 25, 2018)

* New Sidekiq feature: added a filter that ignores error reporting until
  the last try ([#831](https://github.com/airbrake/airbrake/pull/831))

### [v7.2.1][v7.2.1] (January 29, 2018)

* Fixed support for Rails API/Metal
  ([#822](https://github.com/airbrake/airbrake/pull/822))

### [v7.2.0][v7.2.0] (January 10, 2018)

* Added support for Sneakers error handling
  ([#817](https://github.com/airbrake/airbrake/pull/817))

### [v7.1.1][v7.1.1] (December 13, 2017)

* Better fix for apps which don't use ActiveRecord. In some scenarios some pieces
  of ActiveRecord may still be loaded, e.g. the ActiveRecord errors, causing airbrake
  to still fail to startup.
  ([#810](https://github.com/airbrake/airbrake/pull/810))

### [v7.1.0][v7.1.0] (October 20, 2017)

* Started depending on
  [airbrake-ruby-2.5.0](https://github.com/airbrake/airbrake-ruby/releases/tag/v2.5.0)
  ([#807](https://github.com/airbrake/airbrake/pull/807))

### [v7.0.3][v7.0.3] (October 12, 2017)

* Fix URL port reporting for Rails apps running through SSL
  ([#803](https://github.com/airbrake/airbrake/pull/803))

### [v7.0.2][v7.0.2] (September 29, 2017)

* Fixed Sidekiq error `no implicit conversion of String into Integer` when
  ActiveJob is not used ([#799](https://github.com/airbrake/airbrake/pull/799))

### [v7.0.1][v7.0.1] (September 26, 2017)

* Fixed error message for `rake airbrake:test` when current environment is
  ignored ([#796](https://github.com/airbrake/airbrake/pull/796))
* Fixed `undefined local variable or method 'username'` for the Capistrano 2
  integration ([#797](https://github.com/airbrake/airbrake/pull/797))

### [v7.0.0][v7.0.0] (September 21, 2017)

* Deleted deprecated require paths for Capistrano, DelayedJob, Logger, Rails,
  Rake, Resque, Shoryuken & Sidekiq integrations
  ([#792](https://github.com/airbrake/airbrake/pull/792))

### [v6.3.0][v6.3.0] (September 20, 2017)

* Deprecated requiring `airbrake/capistrano/tasks` in favour of
  `airbrake/capistrano` ([#778](https://github.com/airbrake/airbrake/pull/778))
* Port the `airbrake_env` variable to Capistrano 2 integration from airbrake v4
  ([#784](https://github.com/airbrake/airbrake/pull/784))
* Fixed `NameError: uninitialized constant
  Airbrake::Rails::ActiveRecord::ConnectionAdapters`
  ([#780](https://github.com/airbrake/airbrake/pull/780))
* Fixed duplicate errors for ActiveJob integration
  ([#789](https://github.com/airbrake/airbrake/pull/789))
* Started depending on
  [airbrake-ruby-2.4.0](https://github.com/airbrake/airbrake-ruby/releases/tag/v2.4.0)
  ([#790](https://github.com/airbrake/airbrake/pull/790))

### [v6.2.1][v6.2.1] (July 15, 2017)

* Fixed the `airbrake:deploy` Rake task
  ([#769](https://github.com/airbrake/airbrake/pull/769))

### [v6.2.0][v6.2.0] (July 8, 2017)

* Started depending on
  [airbrake-ruby-2.3.0](https://github.com/airbrake/airbrake-ruby/releases/tag/v2.3.0)
  ([#764](https://github.com/airbrake/airbrake/pull/764))
* Fixed Rake integration not reporting test errors or deploys in plain Ruby
  projects ([#763](https://github.com/airbrake/airbrake/pull/763))

### [v6.1.2][v6.1.2] (June 15, 2017)

* Fixed Rails config generation on Ruby 2.1
  ([#753](https://github.com/airbrake/airbrake/pull/753))
* Added support for `context/userAddr`
  ([#756](https://github.com/airbrake/airbrake/pull/756))
* Fixed Rack integration support for user fields with required parameters
  ([#755](https://github.com/airbrake/airbrake/pull/755))

### [v6.1.1][v6.1.1] (May 23, 2017)

* Fixed `airbrake:deploy` Rake task not reporting deploys
  ([#746](https://github.com/airbrake/airbrake/pull/746))

### [v6.1.0][v6.1.0] (May 11, 2017)

* Started depending on
  [airbrake-ruby-2.2.3](https://github.com/airbrake/airbrake-ruby/releases/tag/v2.2.3)
  ([#741](https://github.com/airbrake/airbrake/pull/741))

### [v6.1.0.rc.1][v6.1.0.rc.1] (May 10, 2017)

* Started appending HTTP request info (method, headers & referer) from Rack to
  the `context` hash instead of the `environment` hash
  ([#703](https://github.com/airbrake/airbrake/pull/703))
* Fixed Rack integration overriding `notice[:params]`
  ([#716](https://github.com/airbrake/airbrake/pull/716))
* Started depending on
  [airbrake-ruby-2.2.0](https://github.com/airbrake/airbrake-ruby/releases/tag/v2.2.0)
  ([#724](https://github.com/airbrake/airbrake/pull/724))
* Deprecated requiring `airbrake/delayed_job/plugin` in favour of
  `airbrake/delayed_job` ([#719](https://github.com/airbrake/airbrake/pull/719))
* Deprecated requiring `airbrake/logger/airbrake_logger` in favour of
  `airbrake/logger` ([#719](https://github.com/airbrake/airbrake/pull/719))
* Deprecated requiring `airbrake/rails/railtie` in favour of `airbrake/railtie`
  ([#719](https://github.com/airbrake/airbrake/pull/719))
* Deprecated requiring `airbrake/rake/task_ext` in favour of `airbrake/rake`
  ([#719](https://github.com/airbrake/airbrake/pull/719))
* Deprecated requiring `airbrake/resque/failure` in favour of `airbrake/resque`
  ([#719](https://github.com/airbrake/airbrake/pull/719))
* Deprecated requiring `airbrake/shoryuken/error_handler` in favour of
  `airbrake/shoryuken` ([#719](https://github.com/airbrake/airbrake/pull/719))
* Deprecated requiring `airbrake/sidekiq/error_handler` in favour of
  `airbrake/sidekiq` ([#719](https://github.com/airbrake/airbrake/pull/719))
* Fixed `airbrake:deploy` task raising `AirbrakeError` when Rails `:environment`
  is already required by some other task
  ([#721](https://github.com/airbrake/airbrake/pull/721))

### [v6.0.0][v6.0.0] (March 21, 2017)

* **IMPORTANT:** removed `Airbrake.add_rack_builder` deprecated
  in [v5.7.0.rc.1](#v570rc1-january-24-2017)
  ([#698](https://github.com/airbrake/airbrake/pull/698))
* Started always closing the default notifier to stop losing exceptions
  occurring in Rake & Resque integrations
  ([#695](https://github.com/airbrake/airbrake/pull/695))
* Started depending on
  [airbrake-ruby-2.0.0](https://github.com/airbrake/airbrake-ruby/releases/tag/v2.0.0)
  ([#699](https://github.com/airbrake/airbrake/pull/699))

### [v5.8.1][v5.8.1] (March 2, 2017)

* Fixed `NoMethodError` when initializing the Rack integration without a
  configured notifier ([#692](https://github.com/airbrake/airbrake/pull/692))

### [v5.8.0][v5.8.0] (March 2, 2017)

* Added a mention of the Logger integration to the Rails initializer
  ([#688](https://github.com/airbrake/airbrake/pull/688))

### [v5.8.0.rc.3][v5.8.0.rc.3] (March 1, 2017)

* Fixed user reporting in the Rails integration, when `current_user` is a
  private method ([#684](https://github.com/airbrake/airbrake/pull/684))
* Completely refatored the Logger integration. It no longer monkey-patches
  `Logger`. There's also no need to `require` it. It stopped supporting
  loglevels below `Logger::WARN`
  ([#685](https://github.com/airbrake/airbrake/pull/685))

### [v5.8.0.rc.2][v5.8.0.rc.2] (February 27, 2017)

* Fixed Rails controller helper methods throwing `NameError`
  ([#681](https://github.com/airbrake/airbrake/pull/681))

### [v5.8.0.rc.1][v5.8.0.rc.1] (February 27, 2017)

* **IMPORTANT:** added Shoryuken integration
  ([#669](https://github.com/airbrake/airbrake/pull/669))
* **IMPORTANT:** added Logger integration
  ([#674](https://github.com/airbrake/airbrake/pull/674))
* Started depending on
  [airbrake-ruby-1.8.0](https://github.com/airbrake/airbrake-ruby/releases/tag/v1.8.0)

### [v5.7.1][v5.7.1] (February 10, 2017)

* Fixed version reporting for Rack applications with Rails-related dependencies
  ([#660](https://github.com/airbrake/airbrake/pull/660))
* Fixed unwanted exceptions for Sidekiq, DelayedJob & Resque when Airbrake is
  unconfigured ([#665](https://github.com/airbrake/airbrake/pull/665))

### [v5.7.0][v5.7.0] (January 26, 2017)

* Included `Airbrake::Rack::RequestBodyFilter` to the Rails config generator
  (commented by default) ([#658](https://github.com/airbrake/airbrake/pull/658))

### [v5.7.0.rc.1][v5.7.0.rc.1] (January 24, 2017)

* **IMPORTANT:** support for Ruby 1.9.2, 1.9.3 & JRuby (1.9-mode) is dropped
  ([#646](https://github.com/airbrake/airbrake/pull/646))
* **IMPORTANT:** deprecated `Airbrake.add_rack_builder` public method call
  ([#651](https://github.com/airbrake/airbrake/pull/651))
* Read up to 4096 bytes from Rack request's body (increased from 512)
  ([#627](https://github.com/airbrake/airbrake/pull/627))
* Fixed unwanted authentication when calling `current_user`, when Warden is
  present ([#643](https://github.com/airbrake/airbrake/pull/643))
* Started depending on
  [airbrake-ruby-1.7.0](https://github.com/airbrake/airbrake-ruby/releases/tag/v1.7.0)
* Stopped collecting HTTP request bodies by default, which started happening
  since [v5.6.1](#v561-october-24-2016). Due to security concerns we now make
  this behaviour optional. Users who need this information can use a new
  predefined filter called `Airbrake::Rack::RequestFilter`
  ([#654](https://github.com/airbrake/airbrake/pull/654))

### [v5.6.1][v5.6.1] (October 24, 2016)

* Fixed Rails bug with regard to the `current_user` method signature having
  parameters, while the library expected none
  ([#619](https://github.com/airbrake/airbrake/pull/619))
* Started collecting HTTP request body for Rack compliant apps
  ([#624](https://github.com/airbrake/airbrake/pull/624))

### [v5.6.0][v5.6.0] (October 18, 2016)

* Added support for multiple notifiers for Rack middleware
  ([#515](https://github.com/airbrake/airbrake/pull/515))
* Started depending on
  [airbrake-ruby-1.6.0](https://github.com/airbrake/airbrake-ruby/releases/tag/v1.6.0)

### [v5.5.0][v5.5.0] (September 14, 2016)

* Started depending on
  [airbrake-ruby-1.5.0](https://github.com/airbrake/airbrake-ruby/releases/tag/v1.5.0)

### [v5.4.5][v5.4.5] (August 23, 2016)

* Fixed possible SystemStackError when using ActiveJob integration
  ([#593](https://github.com/airbrake/airbrake/pull/593))

### [v5.4.4][v5.4.4] (August 10, 2016)

* **IMPORTANT**: fixed ActiveJob integration not re-raising exceptions, which
  resulted into marking failed jobs as successfully completed
  ([#591](https://github.com/airbrake/airbrake/issues/591))
* Fixed Rails runner integration not reporting errors
  ([#585](https://github.com/airbrake/airbrake/issues/585))
* Fixed bug with the [enum_field](https://github.com/jamesgolick/enum_field) gem
  raising errors in Rails apps due to constant names collision. As the result,
  the library does not leak `MyModel::KINDS` constants for every Rails model
  ([#588](https://github.com/airbrake/airbrake/pull/588))

### [v5.4.3][v5.4.3] (July 22, 2016)

* **IMPORTANT**: Fixed support for apps, which don't use ActiveRecord. In v5.4.2
  it broke, so it's recommended to upgrade to the current version (or use v5.4.1
  instead) ([#580](https://github.com/airbrake/airbrake/issues/580))

### [v5.4.2][v5.4.2] (July 15, 2016)

* Fixed Heroku deploy hook error when parsing variables containing `=`
  ([#577](https://github.com/airbrake/airbrake/pull/577))

### [v5.4.1][v5.4.1] (June 21, 2016)

* Fixed Capistrano 3 bug when system has conflicting Rake versions, which would
  raise `Gem::LoadError` ([#564](https://github.com/airbrake/airbrake/pull/564))

### [v5.4.0][v5.4.0] (June 6, 2016)

* Started depending on
  [airbrake-ruby-1.4.0](https://github.com/airbrake/airbrake-ruby/releases/tag/v1.4.0)

### [v5.3.0][v5.3.0] (May 11, 2016)

* Fixed bug in the ActiveJob+Resque integration, where the gem couldn't report
  any exceptions ([#542](https://github.com/airbrake/airbrake/pull/542))
* Started depending on
  [airbrake-ruby-1.3.0](https://github.com/airbrake/airbrake-ruby/releases/tag/v1.3.0)
  ([#548](https://github.com/airbrake/airbrake/pull/548))

### [v5.2.3][v5.2.3] (April 5, 2016)

* Fixed bug in the Rake integration where it couldn't display error message
  coming from the API ([#536](https://github.com/airbrake/airbrake/pull/536))

### [v5.2.2][v5.2.2] (March 24, 2016)

* Fixed grouping for the ActiveJob integration
  ([#533](https://github.com/airbrake/airbrake/pull/533))

### [v5.2.1][v5.2.1] (March 21, 2016)

* **Quickfix**: updated the Rails generator to use the newer
  Blacklisting/Whitelisting API
  ([#530](https://github.com/airbrake/airbrake/pull/530))

### [v5.2.0][v5.2.0] (March 21, 2016)

* **IMPORTANT:** depended on
  [airbrake-ruby-1.2.0](https://github.com/airbrake/airbrake-ruby/releases/tag/v1.2.0)
* Fixed bug when trying to send a test exception with help of the Rake task
  results in an error due to the current environment being ignored
  ([#523](https://github.com/airbrake/airbrake/pull/523))
* Added support for reporting critical exceptions that terminate the process.
  This bit of functionality was moved from
  [airbrake-ruby](https://github.com/airbrake/airbrake-ruby/pull/61)
  ([#526](https://github.com/airbrake/airbrake/pull/526))

### [v5.1.0][v5.1.0] (February 29, 2016)

* Fixed Rake integration sometimes not reporting errors
  ([#513](https://github.com/airbrake/airbrake/pull/513))
* Added a way to attach custom information to notices from Rack requests
  ([#517](https://github.com/airbrake/airbrake/pull/517))
* Added support for Goliath apps (fixes regression from Airbrake v4)
  ([#519](https://github.com/airbrake/airbrake/pull/519))

### [v5.0.5][v5.0.5] (February 9, 2016)

* Fixes issue in the Rack integration when `current_user` is `nil` and we try to
  build from it ([#501](https://github.com/airbrake/airbrake/pull/501))
* Improve the Rack integration by attaching more useful debugging information
  such as HTTP headers and HTTP methods
  ([#499](https://github.com/airbrake/airbrake/pull/499))

### [v5.0.4][v5.0.4] (February 2, 2016)

* Set RACK_ENV and RAILS_ENV in Capistrano 2 integration
  ([#489](https://github.com/airbrake/airbrake/pull/489))
* Removed the hostname information from the Rack integration because the new
  `airbrake-ruby` sends it by default
  ([#495](https://github.com/airbrake/airbrake/pull/495))

### [v5.0.3][v5.0.3] (January 19, 2016)

* Improved RubyMine support
  ([#469](https://github.com/airbrake/airbrake/pull/469))
* Added better support for user reporting for Rails applications (including
  OmniAuth support) ([#466](https://github.com/airbrake/airbrake/pull/466))
* Fixed the Capistrano 2 integration, which was not working at all
  ([#475](https://github.com/airbrake/airbrake/pull/475))

### [v5.0.2][v5.0.2] (January 3, 2016)

* Fixed the bug when Warden user is `nil`
  ([#455](https://github.com/airbrake/airbrake/pull/455))

### [v5.0.1][v5.0.1] (December 21, 2015)

* Fixed Migration Guide discrepancies with regard to Resque and Capistrano
* Using the Capistrano 3 integration, made Airbrake notify of deployments only
  from primary server ([#433](https://github.com/airbrake/airbrake/pull/443))

### [v5.0.0][v5.0.0] (December 18, 2015)

* Minor styling/docs tweaks. No bugs were discovered.

### [v5.0.0.rc.1][v5.0.0.rc.1] (December 11, 2015)

* Version 5 is written from scratch. For the detailed review of the changes see
  [docs/Migration_guide_from_v4_to_v5](docs/Migration_guide_from_v4_to_v5.md)
* For the changes made before v5.0.0, see
  [docs/CHANGELOG-pre-v5](docs/CHANGELOG-pre-v5.txt).

[v5.0.0.rc.1]: https://github.com/airbrake/airbrake/releases/tag/v5.0.0.rc.1
[v5.0.0]: https://github.com/airbrake/airbrake/releases/tag/v5.0.0
[v5.0.1]: https://github.com/airbrake/airbrake/releases/tag/v5.0.1
[v5.0.2]: https://github.com/airbrake/airbrake/releases/tag/v5.0.2
[v5.0.3]: https://github.com/airbrake/airbrake/releases/tag/v5.0.3
[v5.0.4]: https://github.com/airbrake/airbrake/releases/tag/v5.0.4
[v5.0.5]: https://github.com/airbrake/airbrake/releases/tag/v5.0.5
[v5.1.0]: https://github.com/airbrake/airbrake/releases/tag/v5.1.0
[v5.2.0]: https://github.com/airbrake/airbrake/releases/tag/v5.2.0
[v5.2.1]: https://github.com/airbrake/airbrake/releases/tag/v5.2.1
[v5.2.2]: https://github.com/airbrake/airbrake/releases/tag/v5.2.2
[v5.2.3]: https://github.com/airbrake/airbrake/releases/tag/v5.2.3
[v5.3.0]: https://github.com/airbrake/airbrake/releases/tag/v5.3.0
[v5.4.0]: https://github.com/airbrake/airbrake/releases/tag/v5.4.0
[v5.4.1]: https://github.com/airbrake/airbrake/releases/tag/v5.4.1
[v5.4.2]: https://github.com/airbrake/airbrake/releases/tag/v5.4.2
[v5.4.3]: https://github.com/airbrake/airbrake/releases/tag/v5.4.3
[v5.4.4]: https://github.com/airbrake/airbrake/releases/tag/v5.4.4
[v5.4.5]: https://github.com/airbrake/airbrake/releases/tag/v5.4.5
[v5.5.0]: https://github.com/airbrake/airbrake/releases/tag/v5.5.0
[v5.6.0]: https://github.com/airbrake/airbrake/releases/tag/v5.6.0
[v5.6.1]: https://github.com/airbrake/airbrake/releases/tag/v5.6.1
[v5.7.0.rc.1]: https://github.com/airbrake/airbrake/releases/tag/v5.7.0.rc.1
[v5.7.0]: https://github.com/airbrake/airbrake/releases/tag/v5.7.0
[v5.7.1]: https://github.com/airbrake/airbrake/releases/tag/v5.7.1
[v5.8.0.rc.1]: https://github.com/airbrake/airbrake/releases/tag/v5.8.0.rc.1
[v5.8.0.rc.2]: https://github.com/airbrake/airbrake/releases/tag/v5.8.0.rc.2
[v5.8.0.rc.3]: https://github.com/airbrake/airbrake/releases/tag/v5.8.0.rc.3
[v5.8.0]: https://github.com/airbrake/airbrake/releases/tag/v5.8.0
[v5.8.1]: https://github.com/airbrake/airbrake/releases/tag/v5.8.1
[v6.0.0]: https://github.com/airbrake/airbrake/releases/tag/v6.0.0
[v6.1.0.rc.1]: https://github.com/airbrake/airbrake/releases/tag/v6.1.0.rc.1
[v6.1.0]: https://github.com/airbrake/airbrake/releases/tag/v6.1.0
[v6.1.1]: https://github.com/airbrake/airbrake/releases/tag/v6.1.1
[v6.1.2]: https://github.com/airbrake/airbrake/releases/tag/v6.1.2
[v6.2.0]: https://github.com/airbrake/airbrake/releases/tag/v6.2.0
[v6.2.1]: https://github.com/airbrake/airbrake/releases/tag/v6.2.1
[v6.3.0]: https://github.com/airbrake/airbrake/releases/tag/v6.3.0
[v7.0.0]: https://github.com/airbrake/airbrake/releases/tag/v7.0.0
[v7.0.1]: https://github.com/airbrake/airbrake/releases/tag/v7.0.1
[v7.0.2]: https://github.com/airbrake/airbrake/releases/tag/v7.0.2
[v7.0.3]: https://github.com/airbrake/airbrake/releases/tag/v7.0.3
[v7.1.0]: https://github.com/airbrake/airbrake/releases/tag/v7.1.0
[v7.1.1]: https://github.com/airbrake/airbrake/releases/tag/v7.1.1
[v7.2.0]: https://github.com/airbrake/airbrake/releases/tag/v7.2.0
[v7.2.1]: https://github.com/airbrake/airbrake/releases/tag/v7.2.1
[v7.3.0]: https://github.com/airbrake/airbrake/releases/tag/v7.3.0
[v7.3.1]: https://github.com/airbrake/airbrake/releases/tag/v7.3.1
[v7.3.2]: https://github.com/airbrake/airbrake/releases/tag/v7.3.2
[v7.3.3]: https://github.com/airbrake/airbrake/releases/tag/v7.3.3
[v7.3.4]: https://github.com/airbrake/airbrake/releases/tag/v7.3.4
[v7.3.5]: https://github.com/airbrake/airbrake/releases/tag/v7.3.5
[v7.4.0]: https://github.com/airbrake/airbrake/releases/tag/v7.4.0
[v7.5.0.pre.1]: https://github.com/airbrake/airbrake/releases/tag/v7.5.0.pre.1
[v8.0.0.rc.2]: https://github.com/airbrake/airbrake/releases/tag/v8.0.0.rc.2
[v8.0.0.rc.3]: https://github.com/airbrake/airbrake/releases/tag/v8.0.0.rc.3
[v8.0.0.rc.4]: https://github.com/airbrake/airbrake/releases/tag/v8.0.0.rc.4
[v8.0.0.rc.5]: https://github.com/airbrake/airbrake/releases/tag/v8.0.0.rc.5
[v8.0.0.rc.6]: https://github.com/airbrake/airbrake/releases/tag/v8.0.0.rc.6
[v8.0.0.rc.7]: https://github.com/airbrake/airbrake/releases/tag/v8.0.0.rc.7
[v8.0.0.rc.8]: https://github.com/airbrake/airbrake/releases/tag/v8.0.0.rc.8
[v8.0.0.rc.9]: https://github.com/airbrake/airbrake/releases/tag/v8.0.0.rc.9
[v8.0.0]: https://github.com/airbrake/airbrake/releases/tag/v8.0.0
[v8.0.1]: https://github.com/airbrake/airbrake/releases/tag/v8.0.1
[v8.1.0]: https://github.com/airbrake/airbrake/releases/tag/v8.1.0
[v8.1.1]: https://github.com/airbrake/airbrake/releases/tag/v8.1.1
[v8.1.2]: https://github.com/airbrake/airbrake/releases/tag/v8.1.2
[v8.1.3]: https://github.com/airbrake/airbrake/releases/tag/v8.1.3
[v8.1.4]: https://github.com/airbrake/airbrake/releases/tag/v8.1.4
[v8.2.0]: https://github.com/airbrake/airbrake/releases/tag/v8.2.0
[v8.2.1]: https://github.com/airbrake/airbrake/releases/tag/v8.2.1
[v8.3.0]: https://github.com/airbrake/airbrake/releases/tag/v8.3.0
[v8.3.1]: https://github.com/airbrake/airbrake/releases/tag/v8.3.1
[v8.3.2]: https://github.com/airbrake/airbrake/releases/tag/v8.3.2
[v9.0.0]: https://github.com/airbrake/airbrake/releases/tag/v9.0.0
[v9.0.1]: https://github.com/airbrake/airbrake/releases/tag/v9.0.1
[v9.0.2]: https://github.com/airbrake/airbrake/releases/tag/v9.0.2
[v9.1.0]: https://github.com/airbrake/airbrake/releases/tag/v9.1.0
[v9.2.0]: https://github.com/airbrake/airbrake/releases/tag/v9.2.0
[v9.2.1]: https://github.com/airbrake/airbrake/releases/tag/v9.2.1
[v9.2.2]: https://github.com/airbrake/airbrake/releases/tag/v9.2.2
[v9.3.0]: https://github.com/airbrake/airbrake/releases/tag/v9.3.0
[v9.4.0]: https://github.com/airbrake/airbrake/releases/tag/v9.4.0
[v9.4.1]: https://github.com/airbrake/airbrake/releases/tag/v9.4.1
[v9.4.2]: https://github.com/airbrake/airbrake/releases/tag/v9.4.2
[v9.4.3]: https://github.com/airbrake/airbrake/releases/tag/v9.4.3
[v9.4.4]: https://github.com/airbrake/airbrake/releases/tag/v9.4.4
[v9.4.5]: https://github.com/airbrake/airbrake/releases/tag/v9.4.5
[v9.5.0]: https://github.com/airbrake/airbrake/releases/tag/v9.5.0
[v9.5.1]: https://github.com/airbrake/airbrake/releases/tag/v9.5.1
[v9.5.2]: https://github.com/airbrake/airbrake/releases/tag/v9.5.2
[v9.5.3]: https://github.com/airbrake/airbrake/releases/tag/v9.5.3
[v9.5.4]: https://github.com/airbrake/airbrake/releases/tag/v9.5.4
[v9.5.5]: https://github.com/airbrake/airbrake/releases/tag/v9.5.5
[v10.0.0]: https://github.com/airbrake/airbrake/releases/tag/v10.0.0
[v10.0.1]: https://github.com/airbrake/airbrake/releases/tag/v10.0.1
[v10.0.2]: https://github.com/airbrake/airbrake/releases/tag/v10.0.2
[v10.0.3]: https://github.com/airbrake/airbrake/releases/tag/v10.0.3
[v10.0.4]: https://github.com/airbrake/airbrake/releases/tag/v10.0.4
[v10.0.5]: https://github.com/airbrake/airbrake/releases/tag/v10.0.5
[v10.1.0.rc.1]: https://github.com/airbrake/airbrake/releases/tag/v10.1.0.rc.1
[v11.0.0]: https://github.com/airbrake/airbrake/releases/tag/v11.0.0
[v11.0.1]: https://github.com/airbrake/airbrake/releases/tag/v11.0.1
[v11.0.2]: https://github.com/airbrake/airbrake/releases/tag/v11.0.2
[v11.0.3]: https://github.com/airbrake/airbrake/releases/tag/v11.0.3
[v12.0.0]: https://github.com/airbrake/airbrake/releases/tag/v12.0.0
