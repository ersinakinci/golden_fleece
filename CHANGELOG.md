# Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]
### [1.0.0] - 2017-06-15
### Changed
- Consistently stringify all keys for `export_fleece` except for top-level column keys

### [0.1.5] - 2017-06-09
### Fixed
- Subschema defaults no longer ignored in corner cases
- Consistently symbolize all keys for `export_fleece`

### [0.1.4] - 2017-05-26
### Fixed
- nil booleans values no longer casted into true under certain cases

### [0.1.3] - 2017-05-26
### Fixed
- Remove caching from value computations, which didn't make sense because we were caching model instance values at the model class level.
- Wrong dates in this change log :-)

### [0.1.2] - 2017-05-26
### Changed
- Allow redefining individual schemas

### Fixed
- Validation no longer stops after encountering a single invalid key in a hash

## [0.1.1] - 2017-05-25
### Fixed
- IMPORTANT: Fixed how normalization works when saving, no longer clobbers JSON

## 0.1.0 - 2017-05-25
### Added
- Initial commit
- Schemas
- Validation (types and formats)
- Normalization
- Exporting
- Getters
- Specs

[Unreleased]: https://github.com/earksiinni/golden_fleece/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/earksiinni/golden_fleece/compare/v0.1.5...v1.0.0
[0.1.5]: https://github.com/earksiinni/golden_fleece/compare/v0.1.4...v0.1.5
[0.1.4]: https://github.com/earksiinni/golden_fleece/compare/v0.1.3...v0.1.4
[0.1.3]: https://github.com/earksiinni/golden_fleece/compare/v0.1.2...v0.1.3
[0.1.2]: https://github.com/earksiinni/golden_fleece/compare/v0.1.1...v0.1.2
[0.1.1]: https://github.com/earksiinni/golden_fleece/compare/v0.1.0...v0.1.1
