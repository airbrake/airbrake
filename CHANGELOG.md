Airbrake Changelog
==================

### master

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
