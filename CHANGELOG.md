# CHANGELOG for `git_lib`

Inspired by [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

Note: this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - Unreleased
### Changed
- Add required `repository:` to `GitCommit`.

## [1.2.0] - 2020-07-13
### Added
- Add support for Rails 5 and 6.
- Add Appraisal and Jenkinsfile to test Rails 4, 5, 6.

### Changed
- Modernize gemspec and Gemfile some more.
- Allow Activesupport > 4.

## [1.1.1] - 2020-06-23
### Changed
- Allow Rails '~> 4.2'.
- Clean up gemspec and Gemfile; bundle update.
- Add magic frozen_string_literal: true comment everywhere.
- Clean up Rakefile.

[2.0.0]: https://github.com/Invoca/git_lib/compare/v1.2.0...v2.0.0
[1.2.0]: https://github.com/Invoca/git_lib/compare/v1.1.1...v1.2.0
[1.1.1]: https://github.com/Invoca/git_lib/compare/v1.1.0...v1.1.1
