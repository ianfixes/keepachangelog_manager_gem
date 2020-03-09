
# `keepachangelog_manager` Ruby gem for your CHANGELOG.md
[![Gem Version](https://badge.fury.io/rb/keepachangelog_manager.svg)](https://rubygems.org/gems/keepachangelog_manager)
[![Documentation](http://img.shields.io/badge/docs-rdoc.info-blue.svg)](http://www.rubydoc.info/gems/keepachangelog_manager/0.0.2)
[![Build Status](http://badges.herokuapp.com/travis/ianfixes/keepachangelog_manager_gem?label=build&branch=master)](https://travis-ci.org/ianfixes/keepachangelog_manager_gem)

If you follow the [Keep A Changelog](http://keepachangelog.com) `CHANGELOG.md` style, this gem automates the process of updating the file for a release.

Before:
```markdown
# Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]
### Added

### Changed
* Everything

### Deprecated

### Removed

### Fixed

### Security


## [0.0.1] - 2018-12-19
### Added
* Initial stuff


[Unreleased]: https://github.com/ianfixes/keepachangelog_manager_gem/compare/v0.0.1...HEAD
[0.0.1]: https://github.com/ianfixes/keepachangelog_manager_gem/compare/v0.0.0...v0.0.1
```

After running `bundle exec keepachangelog_manager.rb --increment-minor`:

```markdown
# Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]
### Added

### Changed

### Deprecated

### Removed

### Fixed

### Security


## [0.1.0] - 2019-01-23
### Changed
* Everything


## [0.0.1] - 2018-12-19
### Added
* Initial stuff


[Unreleased]: https://github.com/ianfixes/keepachangelog_manager_gem/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/ianfixes/keepachangelog_manager_gem/compare/v0.0.1...v0.1.0
[0.0.1]: https://github.com/ianfixes/keepachangelog_manager_gem/compare/v0.0.0...v0.0.1
```


## Installation In Your GitHub Project

Add the following to your `Gemfile`:

```ruby
source 'https://rubygems.org'
gem 'keepachangelog_manager'
```

## Author

This gem was written by Ian Katz (ianfixes@gmail.com) in 2019.  It's released under the Apache 2.0 license.


## See Also

* [Contributing](CONTRIBUTING.md)
