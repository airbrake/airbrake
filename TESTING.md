Running the suite
=================

Since the notifier must run on many versions of Rails, running its test suite is slightly different than you may be used to.

First execute the following command:

    rake vendor_test_gems
    # NOT: bundle exec rake vendor_test_gems

This command will download the various versions of Rails that the notifier must be tested against.

Then, to start the suite, run

    rake

Note: do NOT use 'bundle exec rake'.

For Maintainers
================

When developing the Hoptoad Notifier, be sure to use the integration test against an existing project on staging before pushing to master.

    ./script/integration_test.rb <test project's api key> <staging server hostname>

    ./script/integration_test.rb <test project's api key> <staging server hostname> secure
