# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased] - 2026-06-04

### Added
- **Floating Point Support**: Implemented manual IEEE 754 packing and unpacking in pure SageLang for full 64-bit double support in the VM and compiler.
- **Exception Handling**: Added support for `try/catch/finally` blocks in `MetalVM`.
- **Dynamic Module Loading**: Implemented the `IMPORT` opcode to allow runtime loading of external `.sgvm` files.
- **Enhanced Flow Control**: Switched to relative jumps for better compatibility with the standard SageLang bytecode format.
- **Improved AOT Support**: Optimized tools to work seamlessly as compiled binaries.
- **Build System**: Introduced a `Makefile` for compiling `sgvm.sage` and `sgvmc.sage` into native binaries.

### Fixed
- **Compatibility**: Refactored tools to use global functions (e.g., `push()`, `pop()`, `dict_has()`) for better AOT backend compatibility.
- **String Processing**: Implemented robust manual string slicing and trimming to ensure consistent behavior across backends.
- **Argument Parsing**: Improved argument detection to handle both interpreted and compiled execution modes.
- **Module Shadowing**: Fixed an issue where `io.readbytes` was unavailable due to library shadowing.
