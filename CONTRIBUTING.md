How to contribute
=================

Pull requests
-------------

<img align="right" src="https://img-fotki.yandex.ru/get/15568/98991937.1f/0_b5d09_41234679_orig"/>

We love your contributions, thanks for taking the time to contribute!

It's really easy to start contributing, just follow these simple steps:

1. [Fork][fork-article] the [repo][airbrake]:

 ![Fork][fork]

2. Run the test suite to make sure the tests pass:

  ```shell
  bundle exec rake
  ```

3. [Create a separate branch][branch], commit your work and push it to your
   fork. If you add comments, please make sure that they are compatible with
   [YARD][yard]:

  ```
  git checkout -b my-branch
  git commit -am
  git push origin my-branch
  ```

4. Verify that your code doesn't offend Rubocop:

  ```
  bundle exec rubocop
  ```

5. Run the test suite again (new tests are always welcome):

  ```
  bundle exec rake
  ```

6. [Make a pull request][pr]

Submitting issues
-----------------

Our [issue tracker][issues] is a perfect place for filing bug reports or
discussing possible features. If you report a bug, consider using the following
template (copy-paste friendly):

```
* Airbrake version: {YOUR VERSION}
* Ruby version: {YOUR VERSION}
* Framework name & version: {YOUR DATA}

#### Airbrake config

    # YOUR CONFIG
    #
    # Make sure to delete any sensitive information
    # such as your project id and project key.

#### Description

{We would be thankful if you provided steps to reproduce the issue, expected &
actual results, any code snippets or even test repositories, so we could clone
it and test}
```

<p align="center">
  <img src="https://img-fotki.yandex.ru/get/4702/98991937.1f/0_b5d0a_ba0c0ee6_orig">
  <b>Build Better Software</b>
</p>

[airbrake]: https://github.com/airbrake/airbrake
[fork-article]: https://help.github.com/articles/fork-a-repo
[fork]: https://img-fotki.yandex.ru/get/3800/98991937.1f/0_b5c39_839c8786_orig
[branch]: https://help.github.com/articles/creating-and-deleting-branches-within-your-repository/
[pr]: https://help.github.com/articles/using-pull-requests
[issues]: https://github.com/airbrake/airbrake/issues
[yard]: http://yardoc.org/
