# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased] - 2026-06-06

### Added
- **SGVM Toolchain**: Initiated work on a standalone, self-hosted distribution.
- **Native Class Support**: Started hardening `sgvm` to support native class instantiation and method dispatch for full bytecode-based execution.

## [0.8.1] - 2026-06-06

### Added
- **Native Bridging Layer**: Implemented a comprehensive bridge to the host SageLang standard library, providing high-performance access to `math`, `io`, `sys`, and `re` modules.
- **Bytecode Verifier**: Added mandatory pre-execution verification for constant references and jump targets in `MetalVM`.
- **Inheritance Support**: Implemented recursive method lookup in `OP_CALL_METHOD` to support class inheritance.
- **O(1) Constant Pool**: Switched to dictionary-based deduplication in the compiler for linear-time builds.
- **Native String Methods**: Added support for calling native `find`, `replace`, and `split` methods on string primitives.
- **Multi-threading Engine**: Implemented full `thread` module support with `spawn`, `join`, `mutex`, `lock`, `unlock`, and `sleep`.
- **Global Interpreter Lock (GIL)**: Added a host-mutex-backed GIL to serialize guest bytecode execution, with smart yielding during blocking calls.
- **FFI & Memory Bridge**: Added `ffi`, `mem`, and `struct` modules for low-level host interop and raw memory management.
- **Guest Sandboxing**: Added `safe_mode` and `ffi_enabled` flags to restrict access to sensitive native modules.
- **Resource Tracking**: Implemented guest-level memory allocation tracking and enforcement of memory limits via `mem.limit()`.
- **GC Control Primitives**: Exposed host garbage collector controls (`gc.collect()`, `gc.stats()`) to the guest VM.

### Fixed
- **Maximum Search Paths Error**: Resolved a critical interpreter error in SageLang by preventing duplicate search paths and increasing the limit to 64.
- **CLI Flag Parsing**: Fixed a bug in the SageLang interpreter where `-I` flags were misidentified as script paths.
- **Call Argument Ordering**: Fixed a VM bug where arguments were passed in reverse order to native functions and methods.
- **Import Binding**: Updated `OP_IMPORT` to correctly return module objects, allowing them to be assigned to global variables.
- **Function Returns**: Correctly pop return value and restore execution state in `run_func`, ensuring `OP_RETURN` works as expected.
- **Constant Table Limit**: Removed the 512-constant limit by dynamically sizing local-to-global mapping tables.

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
