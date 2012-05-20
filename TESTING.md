Running the suite
=================

Since the notifier must run on many versions of Rails, running its test suite is slightly different than you may be used to.

You should start by trusting the .rvmrc file. We come in peace.

Then execute the following command:

    rake vendor_test_gems
    # NOT: bundle exec rake vendor_test_gems

This command will download the various versions of Rails and other gems that the notifier must be tested against.

Then, to start the suite, run

    rake
    # NOT: bundle exec rake


For Maintainers
================

When developing the Airbrake gem, be sure to use the integration test against an existing project on staging before pushing to master.

    ./script/integration_test.rb <test project's api key> <staging server hostname>

    ./script/integration_test.rb <test project's api key> <staging server hostname> secure
