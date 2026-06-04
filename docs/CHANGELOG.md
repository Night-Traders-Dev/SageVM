# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased] - 2026-06-04

### Added
- **Build System**: Introduced a `Makefile` for compiling `sgvm.sage` and `sgvmc.sage` into native binaries.
- **System Installation**: Added `make install` support to install tools to `/usr/local/bin`.
- **Shebang Support**: 
    - `sgvmc` can now prepend a shebang line using the `--shebang` flag.
    - `sgvm` now detects and skips shebang lines, enabling direct execution of `.sgvm` files.
- **Git Integration**: Added `.gitignore` to manage repository cleanliness.

### Fixed
- **Compatibility**: Refactored tools to use global functions (e.g., `push()`, `pop()`, `dict_has()`) for better AOT backend compatibility.
- **String Processing**: Implemented robust manual string slicing and trimming to ensure consistent behavior across backends.
- **Argument Parsing**: Improved argument detection to handle both interpreted and compiled execution modes.
- **Module Shadowing**: Fixed an issue where `io.readbytes` was unavailable due to library shadowing.
