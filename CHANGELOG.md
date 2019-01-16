Airbrake Changelog
==================

### master

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
