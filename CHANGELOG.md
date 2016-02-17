Airbrake Changelog
==================

### master

* Fixed Rake integration sometimes not reporting errors
  ([#513](https://github.com/airbrake/airbrake/pull/513))

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
