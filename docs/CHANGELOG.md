# Changelog

All notable changes to this project will be documented in this file.

## [2026-08-12]

### Added
- **Comprehensive Test Suite Coverage Expansion**:
  - Added `exceptions_unwind.sage` to verify multi-frame call-stack exception propagation and lexical environment/scope cleanup.
  - Added `ffi_builtin.sage` to verify structure, parameters, and function existence in the native `ffi` module.
  - Added `conversions_edge.sage` to assert whitespaces parsing and edge conversions of type cast builtins (`int`, `tonumber`).
  - Added `bitwise_shifts_edge.sage` to assert shift behavior on float operands, negative counts, and nil values.
  - Added `gc_reflect_modules.sage` to assert global scoped reflection structures and predefined host imports.
  - Added `thread_module.sage` to verify proper bridging of native mutex locking and unlocking interfaces.
  - Added `builtin_contains_edge.sage` to document and assert conformance for list search patterns.
  - Added `sys_exec_system.sage` and `sys_no_exec.sage` to verify command dispatching under restricted execution profiles.
  - Added `gpu_module_ops.sage` to test headless simulation of event loops and cursor positioning interfaces.
  - Added `io_file_ops.sage` to test and verify `io.writebytes` and `io.readbytes` native file-system integrations.

### Changed (Optimized)
- **High-Frequency Arithmetic & Comparison Fast-Path**:
  - Inlined a non-allocating type validation fast-path (`a != nil and b != nil and tonumber(a) == a and tonumber(b) == b`) inside VM arithmetic and comparison operators. This avoids calling the standard `type()` builtin which allocates heap-bound dynamic string descriptors via `strdup` in the compiler's emitted C codebase, resulting in a ~30.3% real-time speedup and slashing GC/system time by over 97% on loop benchmarks.
- **Truthiness Evaluation Inlining**:
  - Inlined truthiness check logic inside `OP_JUMP_IF_FALSE`, `OP_NOT`, and `OP_TRUTHY` to bypass standard function dispatch and frame-allocation costs, yielding an additional ~13.3% speedup.
- **Local Assignment Stack Pre-Growing Bypass**:
  - Bypassed costly stack allocation loops in local variable writing (`OP_SET_LOCAL`) when target indices are already within stack boundaries.
- **Inline Scope Lookup Cache Relocation**:
  - Moved the `global_cache_dict[idx]` inline lookup cache checks to the very top of `OP_GET_GLOBAL` and `OP_SET_GLOBAL` to completely bypass constant pool bounds verification on cache hits.
- **Redundant Control Flow Safety Check Removal**:
  - Removed stack depth checks from `OP_JUMP` and `OP_LOOP_BACK` since unconditional control flow jumps do not mutate stack sizes.

### Fixed
- **--no-exec Security Flag Propagation**:
  - Fully wired the CLI `--no-exec` restriction flag from `src/sgvm_cli.sage` through runner configs down to the VMs (`exec_enabled` property) to robustly disable dynamic system execution.
  - Hardened system execution handlers `__builtin_sys_exec` and `__builtin_sys_system` to correctly enforce the `exec_enabled` setting and prevent sandbox bypasses.
- **Compiler Path Quoting**:
  - Single-quoted input and output file paths inside `SGVMCompiler.compile` to prevent command injection and flag injection via shell argument splitting.

## [2026-07-31]

### Added
- **Custom VMSYS Opcodes Synchronization**:
  - Documented and synchronized missing Custom VMSYS VM opcodes (`VMO_NIL` (0x0E), `VMO_TRUE` (0x0F), `VMO_FALSE` (0x10), `VMO_NOT` (0x11), and `VMO_TRUTHY` (0x12)) under Section 4.2 of `docs/ARCHITECTURE.md` to match the SRVM core instruction definitions in `src/srvm/srvm_core.sage`.
- **Playground & Opcode Reference UX/Accessibility Polish**:
  - Documented accessibility improvements to card elements, input clearing, focus states, and aria attributes within the interactive documentation site (`docs/site`).
  - Added keyboard navigation support (`role="button"`, focus rings, Enter/Space key triggers) to collapsible Globals panel and reference cards.
- **Auto-scrolling Virtual Console**:
  - Added real-time auto-scrolling to the Playground console view on stdout updates.

### Fixed
- **Headless UI Verification Screenshot Captures**:
  - Handled Playwright browser rendering locks in headless modes by injecting scripts to clear Three.js WebGL canvas objects before screenshot triggers.

## v1.0.2 (2026-07-29)

### Added
- **Search & Filter Recovery Patterns (Opcode Reference)**:
  - Added a "Reset" and "Clear Search" call-to-action button in the Opcode Reference (`docs/site/src/sections/Opcodes.tsx`) to prevent navigation dead-ends when search results are empty.
- **Auto-Scrolling Virtual Console (Playground)**:
  - Enhanced the virtual console in the VM Playground (`docs/site/src/sections/Playground.tsx`) to automatically scroll to the bottom upon receiving new output, eliminating scroll friction during execution runs.

### Improved
- **Accessibility and Interaction Polish (Opcodes & Playground)**:
  - Enhanced custom interactive elements like category filters and search inputs with explicit `aria-label`, `aria-pressed`, and keyboard-navigable card toggles to improve compatibility with assistive technologies.
  - Implemented complete keyboard accessibility for the collapsible Globals panel in the VM Playground using `role="button"`, `tabIndex={0}`, `aria-expanded`, and Space/Enter `onKeyDown` listeners.
  - Added descriptive ARIA labels to VM Playground controls, including the execution speed range slider, file actions (copy, download, upload), and custom read-only textareas.

## v1.0.1 (2026-07-27)

### Added
- **Foreign Function Interface (FFI) Calling with Type Marshaling**:
  - Implemented `sage_ffi_call` and `sage_ffi_call_full` native functions in `sgvm_debug.c` to support FFI calling via `dlsym`.
  - Added `sage_value_to_c` to support argument type marshaling for `int`, `double`, `string`, `pointer`, and `bytes` types into C-compatible values.
  - Added support for explicit return types (`int`, `double`, `pointer`) in `sage_ffi_call_full`.
  - Enables seamless SageLang -> C FFI calls, critical for integrating with the SageFS kernel driver.
- **Makefile Integration and Targets**:
  - Introduced `test-srvm` and `test-jit` targets in the `Makefile` to simplify running the verification suite for RISC-V and JIT configurations.
  - Enhanced workspace compilation resilience by configuring network-less and GPU-less builds for SageLang core during bootstrap (`SAGE_NO_NET=1 SAGE_NO_GPU=1`).

### Changed
- **Sandboxing and Capabilities Restriction**:
  - Blacklisted guest-side `struct` module import in SVM (`src/svm/sgvm_vm.sage`) under `safe_mode`.
- **Improved Host C Interpreter Precision & Robustness**:
  - Updated `sage_sub`, `sage_mul`, `sage_div`, and `sage_mod` with descriptive debugging details and standardized error behaviors for operand mismatch.

### Fixed
- **Hardened Byte Writing**:
  - Updated `sage_io_writebytes` to support writing both raw `SAGE_TAG_BYTES` and `SAGE_TAG_ARRAY` objects.
  - Added security verification in `sage_io_writebytes` to default non-number tags in arrays to 0 instead of causing host crashes.

## v1.0.0 (2026-07-24)

### Highlights & 100% Test Conformance
- **100% Coverage Test Suite Pass Rate**: Achieved 79/79 passed tests across the complete SageVM coverage suite.
- **Opcode Hex Translation Alignment**: Fixed opcode translation mapping in `sgvm_compiler.sage` to align 0-based host bytecode opcodes (`BC_OP_GET_LOCAL`, `BC_OP_SET_LOCAL`, `BC_OP_RAISE`, `BC_OP_JUMP`, `BC_OP_CALL`) to SageVM execution layout.
- **Native Generator Engine**: Implemented full state preservation and resumption for `OP_CREATE_GENERATOR` (`0x3e`), `OP_YIELD` (`0x3d`), and `OP_GENERATOR_NEXT` / `next()` (`0x3f`).
- **Multi-Chunk Script Execution**: Added `exit_requested` process termination tracking to reset `halted` between top-level script chunks without premature exit.
- **Security Sandboxing Hardening**: Enforced protected dictionary object mutation restrictions in `safe_mode` for `push`/`pop` builtins.
- **General Availability (GA)**: Official 1.0.0 milestone release for SageVM.

## v0.9.9 (2026-07-23)

### Self-Hosting & Compilation
- **Stack VM self-hosting**: `sagevm_standalone.sage` compiles to `.sgvm` (~96 KB) and executes correctly — SageVM compiles itself.
- **RISC-V compilation pipeline**: Full `.sage` → SVM bytecode → RV64I instruction translation → `.sgrv` binary (~199 KB) via `StackToRiscVTranslator`.
- **CLI dispatch fix**: Moved direct subcommand checks (`run`, `compile`, `dis`, `hex`) ahead of symlink shorthand matching to prevent misrouting.
- **Standalone build pipeline**: Python concatenation script strips module imports and rewrites class constructors for single-file standalone compilation.

### MetalVM Parity (SVM)
- **Truthiness conformance**: `is_truthy()` helper ensures only `nil`, `false`, and `0` are falsy — empty strings, arrays, and dicts are now truthy (matching MetalVM spec).
- **Deep structural equality**: `equal_val()` for `OP_EQUAL` / `OP_NOT_EQUAL` performs recursive structural comparison for dicts, arrays, and tuples.
- **String repetition**: `OP_MUL` now supports `"a" * 3` → `"aaa"` via `str_repeat()` helper.
- **Division-by-zero → nil**: `OP_DIV` and `OP_MOD` return `nil` on zero divisor instead of halting the VM.
- **GPU opcode stubs**: Opcodes 59–86 handled with safe no-op/default behavior in `execute_op()`.
- **`OP_HALT` dispatch**: Added to `execute_op()` fallback path.

### SRVM Fixes
- **`OP_LUI` dispatch**: Added `elif op == OP_LUI` to `SRVMVM.step()` — required for large immediate values emitted by `emit_load_imm()`.
- **Module namespace stripping**: Removed all `srvm_core.`, `sgvm_core.`, `srvm_profiler.` prefixes from SRVM source files for standalone build compatibility.
- **`pop_reg()` safety helper**: Returns fallback register `x11` when `reg_stack` is empty, preventing `nil` from leaking into instruction encoding.
- **Array mutation fix**: `TypeProfiler.analyze()` uses append-only `push(result, hint)` instead of index assignment (which crashes the host C runtime).

### Security & Correctness
- **[C5] Division-by-zero guards**: Added runtime checks for `OP_DIV` and `OP_MOD` in both SVM hot-path and `execute_op()` fallback to prevent host crashes.
- **[C1] SRVM register allocator spilling**: Fixed silent data corruption when expressions require more than 8 temporary registers by implementing stack spilling.
- **[C3] SRVM unsigned operations**: Fixed `SRLI` vs `SRAI` instruction semantics and documented `BLTU`/`BGEU` limitation.
- **[C7] --no-exec flag**: Added `exec_enabled` property and `--no-exec` CLI flag to disable `OP_EXEC_AST_STMT` independently of safe mode.
- **[M5] Safe mode host function guard**: Added safe_mode check to prevent direct host function/native fn calls via `OP_CALL`.
- **[M12] OP_DEFINE_GLOBAL bounds check**: Added constant pool bounds validation.
- **Hardened byte writing**: `sage_io_writebytes` in `sgvm_debug.c` supports both `SAGE_TAG_BYTES` and `SAGE_TAG_ARRAY` safely.

### Features
- **[H7] SVM builtin parity**: Added 16 missing builtins to SVM `call_builtin()`: `push`, `pop`, `chr`, `ord`, `startswith`, `endswith`, `contains`, `join`, `split`, `replace`, `upper`, `lower`, `strip`, `dict_has`, `dict_keys`, `dict_values`.
- **[H8] Generator opcode stubs**: Added meaningful error messages for unimplemented `OP_YIELD`, `OP_CREATE_GENERATOR`, `OP_GENERATOR_NEXT`.

### Performance
- **[H2] SRVM x0 optimization**: Only reset x[0] when rd==0 instead of every cycle.
- **[M10] Profiler fix**: `TypeProfiler.analyze()` now returns properly-sized arrays, preventing out-of-bounds access in the SRVM compiler.
- **[M11] SRVM stack growth**: Increased default SRVM stack from 1,000 to 4,096 slots.

### Build & Infrastructure
- **[M1] Version synchronization**: Unified version to 0.9.9 across VERSION, CLI, and sagemake.
- **[M8] sagemake install**: Now supports `PREFIX` env var for custom install paths; graceful sudo fallback.
- **[L1] Cleanup**: Removed stale `.sage.backup` files.
- Added 6 new test suites: `div_zero_safety`, `builtin_string_ops`, `builtin_collection_ops`, `security_host_func`, `chr_ord_ops`, `split_join_ops`.


## [2026-07-16]

### Added
- **Two-Scope Global Fast-Path (SVM)**: Extended `OP_GET_GLOBAL` and `OP_SET_GLOBAL` fast-paths to also optimize variable resolution when the scope depth is exactly 2.
- **Inlined Property Operations (SVM)**: Fully inlined property lookup (`OP_GET_PROPERTY`) and property assignment (`OP_SET_PROPERTY`) directly into `MetalVM.run`, reducing instruction delegation and call overhead.
- **In-Place Stack Peeking & Modification (SVM)**: Optimized `OP_SET_GLOBAL`, `OP_GET_INDEX`, `OP_SET_INDEX`, `OP_GET_PROPERTY`, and `OP_SET_PROPERTY` to peek at operand values and modify the stack in-place, eliminating pop/push allocation overhead.
- **Enhanced Sandboxing (SVM)**: Restricted guest import of the host `struct` module in `safe_mode` via `OP_IMPORT` blacklist enforcement, matching security constraints.
- **Comprehensive Test Coverage**: Added dedicated test coverage including `generators.sage` (generators & `yield`), `security_builtin_protection.sage` (`__builtin__` key mutation checks), `import_user_module.sage` (non-native import dummy handling), `array_len_edge.sage` (`len()` edge cases), and `dup_targeted.sage` (targeted `OP_DUP` verification).

### Changed
- **Makefile Resilience**: Configured `SAGE_NO_NET=1 SAGE_NO_GPU=1` and `CFLAGS_EXTRA` flags when compiling the host `sage` binary to ensure compatibility with restricted environments.
- **Documentation Sync**: Synchronized architectural specs, execution pipelines, and roadmap statuses with the 2026-07-16 conformance state.

## [2026-07-15]

### Added
- **Single-Scope Global Fast-Path (SVM)**: Implemented a high-performance fast-path for `OP_GET_GLOBAL` and `OP_SET_GLOBAL` in `MetalVM.run` when execution is limited to the global scope.
- **Scopes Depth Caching (SVM)**: Cached `len(scopes)` as a local variable in the hot loop to eliminate repeated property lookup overhead.
- **Expanded Hot-Path Dispatch (SVM)**: Frequency-optimized the instruction dispatch loop to include inlined branches for `OP_TRUTHY`, `OP_PRINT`, `OP_NEGATE`, and `OP_ARRAY_LEN`.

### Fixed
- **SVM Builtin Protection**: Hardened `is_protected` logic in the stack-based backend to include `__builtin__` key validation, achieving security parity with the RISC-V backend.

### Changed
- **Documentation Sync**: Synchronized architectural and technical specifications with the 2026-07-15 conformance state.

## [2026-07-13]

### Added
- **Interpreter Hot-Loop Optimization (SVM)**: Inlined over 35 frequent opcodes (arithmetic, logic, stack ops, locals/globals) directly into `MetalVM.run` and cached `scopes_len` as a local variable, significantly reducing dispatch overhead.

### Fixed
- **SRVM Security Hardening**: Hardened `is_protected` logic in the RISC-V backend to include `__builtin__` key validation, ensuring core host-provided utility structures remain immutable to guest code.

### Changed
- **Documentation Sync**: Synchronized architectural and technical specifications with the 2026-07-13 conformance state.

## [2026-07-10]

### Added
- **SVM Generator Support**: Added core opcode definitions (`OP_YIELD`, `OP_CREATE_GENERATOR`, `OP_GENERATOR_NEXT`) and compiler emission logic for generator functions in the SVM backend.

### Fixed
- **Critical Sandbox Escape (SVM)**: Resolved a security vulnerability in `OP_CALL_METHOD` where internal `__` prefixed properties could be leaked or accessed in `safe_mode`.

### Changed
- **Documentation Sync**: Synchronized architectural and technical specifications with the 2026-07-10 conformance state; documented the expanded 5-opcode shift regression following the introduction of generator opcodes in the authoritative spec.

## [2026-07-08]

### Changed
- **Documentation Sync**: Synchronized architectural and technical specifications with the 2026-07-08 conformance state; documented the 2-opcode shift regression and implementation gaps in the SRVM interpreter.
- **SRVM Conformance Audit**: Identified and documented missing implementations for `VMO_NOP`, `VMO_IMPORT`, and `VMO_EXEC_AST` in the RISC-V backend.

## [2026-07-07]

### Fixed
- **Interpreter Hardening**: Implemented explicit bounds checks for constant pool and chunk indexing across both SVM and SRVM interpreters to prevent out-of-bounds access vulnerabilities.

### Changed
- **Native Bridge Completion (SVM)**: Finalized and verified native bridge coverage for all `mem` (alloc, free, read, write, size) and `struct` (def, new, get, set, size) operations in the SVM backend.
- **Documentation Sync**: Synchronized architectural and technical specifications with the 2026-07-07 conformance state.

## [2026-07-06]

### Added
- **SRVM Comparison Engine**: Added `VMO_CMP_BINARY` opcode to the SRVM core for generic binary comparisons (EQ, NEQ, LT, GT, LE, GE).
- **SRVM Compiler Integration**: Integrated `VMO_CMP_BINARY` into the SRVM compiler's code emission pass to support complex conditional logic.

### Changed
- **Documentation Sync**: Synchronized architectural and technical specifications with the 2026-07-06 conformance state; documented the `VMO_CMP_BINARY` implementation gap in the SRVM interpreter.

## [0.9.22] - 2026-07-05

### Added
- **Compiler Security Hardening**: Upgraded `sgvmc` path validation to use a robust, whitelist-based `is_safe_path` helper, preventing command and flag injection via malicious file paths.

### Changed
- **Native Bridge Expansion (SVM)**: Finalized and verified native bridge coverage for `math` (`abs`, `sqrt`, `sin`, `cos`), `mem` (`read`), and `struct` (`def`) in the SVM backend.
- **Documentation Sync**: Updated architectural and technical specifications to reflect the 2026-07-05 conformance state and newly identified SVM implementation gaps.
## [0.9.22] - 2026-07-04

### Changed
- **Documentation Sync**: Updated technical specifications and architectural documentation to reflect the latest conformance audit and architectural findings as of 2026-07-04.

## [0.9.21] - 2026-07-02

### Added
- **Sandbox Hardening (SRVM)**: Implemented strict protection for objects tagged with `__builtin__` in the RISC-V backend, preventing guest corruption of core utility functions in `safe_mode`.

### Fixed
- **Critical Sandbox Bypass (SVM)**: Resolved a high-severity safe mode bypass in `MetalVM` by deferring sensitive module initialization until after the VM's security posture has been fully configured.

### Changed
- **Documentation Sync**: Updated technical specifications and architectural documentation to reflect the latest security hardening and conformance state as of 2026-07-02.

## [0.9.20] - 2026-07-01

### Added
- **Sandbox Hardening (Internal Properties)**: Implemented strict protection in `safe_mode` for internal `__` prefixed properties (excluding `__arg`) and protected host modules in the SVM backend.
- **Native Bridge Expansion**: Continued expansion of `math` module native bridges (`abs`, `sqrt`, `sin`, `cos`) in the SVM backend.

### Changed
- **Interpreter Optimization (SVM)**: Achieved a 4.3x speedup by inlining BE16 decoding and caching VM state (stack, constants) in local variables within the `MetalVM.run` loop.
- **Documentation Sync**: Synchronized technical specifications with the 2026-07-01 conformance audit, documenting the 2-opcode shift regression in Phase 16.

## [0.9.19] - 2026-06-29

### Added
- **Native Bridge Expansion**: Bridged `math.abs` and `math.sqrt` to host functions in the SVM backend, resolving previous return-nil gaps.

### Changed
- **Documentation Sync**: Synchronized architectural and technical specifications with the current implementation state, specifically documenting inlined loop optimizations and local base caching.

## [0.9.18] - 2026-06-28

### Added
- **Native Bridge Expansion**: Implemented or successfully bridged `mem.read`, `struct.def`, `math.sin`, and `math.cos` in the SVM backend.
- **Type Profiling**: Integrated `srvm_profiler.sage` into the RISC-V pipeline for speculative type inference.

### Changed
- **Interpreter Optimization (SVM)**: Inlined instruction decoding and operand fetching into the main execution loop; cached `current_local_base` to accelerate local variable access.
- **Interpreter Optimization (SRVM)**: Removed legacy JIT hot-path detection stubs from the RISC-V interpreter loop, yielding significant performance gains in arithmetic benchmarks.

### Fixed
- **Opcode Conformance**: Performed a comprehensive audit against `bytecode.h` and synchronized documentation regarding the Phase 16 GPU instruction shift and local variable collisions.

## [0.9.17] - 2026-06-27

### Added
- **SVM Security Parity**: Implemented internal resource limits (stack, call, handler depth) and module protection guards (`is_protected` checks) in the SVM interpreter to achieve parity with the RISC-V backend.
- **SRVM Builtin Expansion**: Confirmed implementation of 13 string and collection utility builtins (`startswith`, `contains`, `replace`, etc.) in the RISC-V backend.

### Fixed
- **Documentation Alignment**: Synchronized technical specifications with the current 0.9.8 implementation state and identified gaps in the SVM disassembler's opcode mapping.

## [0.9.16] - 2026-06-26

### Added
- **SRVM Sandboxing**: Implemented security sandboxing for the RISC-V backend, including `is_protected` checks for host modules and `safe_mode` enforcement.
- **SRVM Resource Limits**: Integrated mandatory runtime limits for call depth (1,024), try depth (1,024), and max array size (1,000,000) in the SRVM interpreter.

### Fixed
- **Makefile Resilience**: Added a mock `curl/curl.h` and automated workaround in the `test` target to allow building the SageLang host on systems without `libcurl` installed.

## [0.9.15] - 2026-06-25

### Added
- **CLI Feedback**: Implemented ANSI colorized output and centralized tip system for improved user experience.
- **Binary Metrics**: Added reporting of generated binary size (bytes/KB) to the `compile` command.
- **Auto-Detection**: Integrated 4-byte magic header inspection into the unified CLI to automatically route commands to the correct architecture (SVM vs. SRVM).

### Changed
- **Unified Handlers**: Refactored CLI command handlers to leverage centralized `verify_input` for consistent validation across all tools.

### Fixed
- **Documentation Parity**: Identified and documented the critical sandboxing gap in the SRVM backend and truthiness conformance bug in the SVM interpreter.

## [0.9.14] - 2026-06-24

### Added
- **Type Profiling**: Added `srvm_profiler.sage` to the SRVM pipeline for speculative type inference.
- **Network Shim**: Added `src/svm/net.sage` to provide a guest-accessible shim for the native network module.

### Changed
- **Opcode Alignment**: Synchronized SVM opcode indices 59-86 with the authoritative `bytecode.h`, resolving long-standing encoding mismatches for the GPU instruction set.
- **Documentation Sync**: Updated `ARCHITECTURE.md` and `SPEC.md` to reflect the resolved opcode alignment and new JIT/Profiling components.

## [0.9.13] - 2026-06-23

### Added
- **JIT Infrastructure**: Initialized high-performance JIT compilation pipeline in `src/jit/`.
- **Memory Management**: Implemented `ExecutableMemoryManager` with W^X security enforcement.
- **Native Emitter**: Added `CodeEmitter` for translating RV64I Intermediate Representation to binary instructions.

### Changed
- **Documentation Sync**: Synchronized technical specifications and architectural documentation with the 2026-06-23 implementation state.

## [0.9.12] - 2026-06-21

### Changed
- **Documentation Sync**: Updated `ARCHITECTURE.md` and `SPEC.md` to reflect current truthiness semantics and SRVM-delegated builtins.
- **Opcode Audit**: Verified SVM/SRVM opcode tables against `bytecode.h` and documented collision risks at 87-88.

### Fixed
- **Status Alignment**: Flagged implementation gaps for string/collection builtins in the SVM interpreter as documented in modern test suites.

## [0.9.11] - 2026-06-20

### Added
- **Local Variable Support**: Fully implemented `OP_GET_LOCAL` (88) and `OP_SET_LOCAL` (89) in the SVM interpreter.
- **Enhanced Test Coverage**: Added `tests/indexing_assign.sage` for array/dictionary assignment and `tests/builtins_gc_reflect.sage` for garbage collection and reflection stubs.

### Changed
- **Compiler Alignment**: Updated `sgvmc` to correctly remap local variable opcodes (0x3B/0x3C) to SVM-internal indices (88/89).

## [0.9.10] - 2026-06-19

### Added
- **Truthiness Specification**: Documented boolean context evaluation semantics in `SPEC.md`.
- **SRVM Builtins**: Expanded `ARCHITECTURE.md` with 16 new SRVM-optimized builtins (string/collection utilities).
- **Safety Limits**: Documented the fixed 1,000-slot stack limit for the SRVM backend in `SPEC.md`.

### Changed
- **Documentation Alignment**: Synchronized SVM/SRVM opcode tables and verified against authoritative `bytecode.h`.
- **Roadmap Cleanup**: Refined `ROADMAP.md` checkboxes and status descriptions.

## [0.9.9] - 2026-06-18

### Added
- **SGRV Specification**: Added Section 2.2 to `SPEC.md` detailing the register-based (RISC-V) binary format.
- **Opcode Gaps**: Identified and documented missing `sgvmc` emission logic for `OP_MATH_PRINTM` (87).
- **Core Builtins Docs**: Added `slice`, `gc_*`, and `reflect_*` builtins to `ARCHITECTURE.md`.

### Changed
- **CLI Documentation**: Synchronized `README.md` with all implemented flags (`--riscv`, `--sage`, `--svm`, `--safe`, `--no-ffi`).
- **Native Bridge Status**: Updated `ARCHITECTURE.md` and `ROADMAP.md` to accurately reflect implementation of `ffi`, `mem`, and `struct` modules.
- **Roadmap Refinement**: Transitioned roadmap items to checkbox format and added `re` and `json` as missing bridge targets.

### Fixed
- **SRVM Implementation Gaps**: Identified and added missing register-based opcodes (`VMO_IMPORT`, `OBJ_SLICE`, etc.) to `ROADMAP.md`.

## [0.9.8] - 2026-06-17

### Added
- **Local Variable Constants**: Added `OP_GET_LOCAL` (88) and `OP_SET_LOCAL` (89) constants to `sgvm_core.sage`.
- **Path Sanitization**: Implemented strict validation of input/output file paths in the compiler to prevent shell command injection.

### Changed
- **CLI Documentation**: Synchronized `README.md` with the current CLI flags (`--safe`, `--no-ffi`).
- **Version Alignment**: Updated reported version to `0.9.8` in documentation to match `sgvm_cli.sage`.

## [0.9.7] - 2026-06-16

### Added
- **100% Opcode Parity**: Achieved full synchronization with the authoritative `bytecode.h` from SageLang (89 opcodes total, 0-87 and 255).
- **Matrix Visualization**: Implemented native `math.printm` support in both the VM and compiler.
- **Mobile-Friendly Docs**: Improved the architecture graph visualization with dynamic resizing and touch support.

### Changed
- **OOP Engine Refactor**: Significantly improved `OP_CALL_METHOD` to correctly handle direct class method calls and inheritance.
- **Documentation Maintenance**: Updated `ARCHITECTURE.md` and `ROADMAP.md` to reflect current implementation status, removing legacy warnings.

### Fixed
- **Opcode Mapping Fix**: Corrected the critical `OP_RAISE` collision (now correctly mapped to 58, not 68).
- **Scope Persistence Bug**: Fixed a VM bug where `OP_RETURN` prematurely popped the global scope in top-level chunks.
- **Output Interference**: Silenced intrusive debug logs in `MetalVM.init` that caused test suite mismatches.

## [0.9.6] - 2026-06-15

### Added
- **Core Builtins**: Exposed common host-level functions (`clock`, `str`, `int`, `tonumber`, `len`, `print`, `range`, `type`) to the guest global scope.
- **Experimental Native Modules**: Added `gc` and `reflect` modules as experimental stubs in the native bridge.

### Fixed
- **Opcode Encoding Audit**: Flagged a critical encoding collision where `OP_RAISE` (58) is incorrectly mapped to 68 (shared with `OP_GPU_END_COMMANDS`) by the `sgvmc` compiler.
- **Compiler Instruction Gaps**: Identified missing implementation for `OP_MATH_PRINTM` (87) in the compiler's binary emission pass.
- **VM Control Flow Gaps**: Identified missing handler implementations for `OP_BREAK` and `OP_CONTINUE` in the `MetalVM` interpreter.

### Changed
- **Documentation Parity**: Synchronized technical specifications with the current implementation, including explicit runtime safety limits and updated native bridge coverage.

## [0.9.5] - 2026-06-14

### Added
- **Internal Security Limits**: Implemented mandatory runtime limits for stack depth (65,536), call depth (1,024), and exception handler nesting (1,024) to prevent Denial of Service (DoS).
- **CLI UX Standard**: Unified `-h/--help` and `-v/--version` flag support across `sgvm` and `sgvmc` with consistent formatting and version reporting.
- **ML Native Bridge**: Integrated `ml_native` module into the native delegation bridge.

### Fixed
- **Native Bridge Regressions**: Flagged missing support for `re` and `json` modules in the roadmap for future restoration.

## [0.9.4] - 2026-06-14

### Added
- **SageLang v3.8.4 Support**: Updated the core compiler submodule and synchronized VM logic with the latest language specifications.
- **AST Execution Bridge**: Implemented `OP_EXEC_AST_STMT` delegation to the host `sys.exec`, enabling execution of non-lowered code segments within the VM.
- **Expanded Native Library Access**: Broadened the delegation bridge in `OP_IMPORT` to include `json` and `re` (regex) modules from the host standard library.

### Changed
- **Compiler Refactoring**: Cleaned up the VM implementation, removing legacy `end` keywords and standardizing loop increment logic for better performance on modern Sage backends.

### Fixed
- **Critical Exception Handler Leak**: Fixed a major architectural bug where exception handlers were not properly scoped to their call frames, leading to "leaked" handlers that erroneously caught exceptions in parent frames after a function returned.
- **Stack & Scope Unwinding**: Improved `OP_RAISE` to perform a full unwinding of the call stack, local scopes, and operand stack to correctly restore the VM state at the catch site.
- **Opcode Documentation Parity**: Performed a comprehensive audit and synchronization of the documentation website's opcode tables against the core implementation.

## [0.9.3] - 2026-06-09

### Added
- **Opcodes constants mapping**: Refactored interpreter's `run_step()` loop from magic numbers to named `OP_*` opcode constants.

### Fixed
- **Loop control safety**: Implemented explicit unexpected loop control error handling for `OP_BREAK` and `OP_CONTINUE` opcodes to match C VM behavior.
- **Delegation bridge stack safety**: Expanded dynamic guest-to-host delegation call argument capacity up to 8 arguments and added fallback checks to prevent stack corruption on limit violations.
- **Loader bounds checking**: Added robust bounds checking assertions when parsing headers, constants, string lengths, and chunk sizes to prevent out-of-bounds crashes on malformed/truncated binaries.

### Changed
- **Compiler Refactoring**: Restructured compiler's main entry point `compile()` into distinct helper methods (`first_pass()` and `second_pass()`) for a clean two-pass execution.

## [0.9.2] - 2026-06-08

### Added
- **Native Bridge Modules**: Re-implemented and exposed `re`, `ffi`, `mem`, `struct`, and `gc` native modules to guest VM.
- **AST Fallback**: Implemented `OP_EXEC_AST_STMT` to allow execution of non-lowered code via `sys.exec()`.

### Fixed
- **Execution Logic**: Robustly fixed chunk execution by scanning bytecode to correctly identify and skip function chunks.
- **VM Fall-through**: Added missing `return true` handlers to `OP_CONSTANT`, `OP_NIL`, `OP_TRUE`, `OP_FALSE`, `OP_POP`, `OP_PRINT`, `OP_RETURN`, and `OP_HALT` to ensure proper instruction completion.
- **Bytecode Serialization**: Reordered binary blob construction in the compiler to write constants before the main code, aligning with `MetalVM` loader expectations.

## [0.9.1] - 2026-06-08

### Added
- **Delegation Bridge**: Implemented a "Guest-to-Host" bridge allowing SageVM to delegate GPU opcodes, native imports, and complex calls directly to the host SageLang interpreter.
- **Unified Build System (SageMake)**: Replaced legacy `build.sh` with a modern, Python-based `sagemake` orchestrator using `rich` for visual feedback.
- **Host Call API**: Integrated `sys.call` for dynamic invocation of host native functions from the guest VM.

### Fixed
- **Opcode Stability**: Converted opcode definitions to integer literals to ensure exact matching and reliable execution across all backends.
- **Indentation Syntax**: Final cleanup of legacy `end` keywords and one-liner syntax to strictly adhere to SageLang's indentation-based blocks.

## [0.9.0] - 2026-06-08

### Added
- **Full Opcode Parity**: Synchronized all opcodes with SageLang v3.8.4, including support for classes, inheritance, exceptions, and GPU hot-path stubs.
- **OOP Engine**: Implemented native class instantiation, method dispatch, and attribute access in `sgvm_vm.sage`.
- **Exception Handling**: Full support for `try/catch/finally` and `raise` in the VM.
- **Advanced Data Structures**: Added native support for `slice`, `tuple`, and complex `dict` operations.
- **Flexible Compiler**: Upgraded `sgvmc.sage` to handle variable-length operands (1-4 bytes) and automatic `.sage` -> `.svm` -> `.sgvm` translation.

### Changed
- **Indentation-based Syntax**: Refactored all tools to strictly follow SageLang's indentation-based blocks, removing legacy `end` keywords.
- **Search Path Precedence**: Updated module loader to prioritize local `lib/` directory relative to the executable for better development workflow.

### Fixed
- **Builtin Mapping**: Fixed AOT compilation issues by using name-based builtin mapping for native host functions.
- **Argument Mapping**: Corrected argument ordering and `self` injection for method calls and constructors.

### Removed
- **Cruft Cleanup**: Aggressively removed legacy `.svm`, `.sgvm` artifacts and old debug drafts (`run_step_draft.sage`, etc.).

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
