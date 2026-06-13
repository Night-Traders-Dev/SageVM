# SGVM Roadmap: Unsupported Features

This document outlines the features and standard library modules currently unsupported by the SGVM interpreter (`sgvm.sage`). Tasks are categorized by their implementation difficulty.

## ✅ Supported Features
- **Floating Point Binary Loading**: Full IEEE 754 64-bit double support for packing and unpacking.
- **Exception Handling**: Full support for `try/catch/finally` via `SETUP_TRY`, `END_TRY`, and `RAISE`.
- **Enhanced Flow Control**: Correct handling of relative jumps and loop control opcodes.
- **Dynamic Imports**: Ability to load and execute external `.sgvm` modules at runtime.
- **Native Bridging Layer**: Support for `math`, `io`, `sys`, `net`, `gpu`, and `ml_native` modules via host SageLang mapping.
- **Multi-threading**: Full support for `thread` module with a Global Interpreter Lock (GIL) and result capturing.
- **Resource Management**: Guest memory tracking and enforcement via host-provided limits.
- **GPU Hot-Paths**: Implementation of the `BC_OP_GPU_*` opcodes for Vulkan/OpenGL acceleration via host delegation.

## 🟡 Medium Difficulty (Native Bridging)
- **Native Bridge Modules**: Re-implement and expose `re`, `ffi`, `mem`, `struct`, and `gc` native modules to guest VM (restoration of missing functionality).
- **Security Sandboxing**: Implement `safe_mode` and `ffi_enabled` flags to restrict access to sensitive native modules.

## 🔴 High Difficulty (Complex Systems)
These tasks involve significant architectural additions or complex resource management.

- **Networking**: Full implementation of `net`, `socket`, and `http` modules, requiring a safe abstraction of the host's networking stack.

## 🟣 Research / Future
- **JIT/AOT Compilation**: Transitioning from a pure interpreter to a system that emits native machine code for the target architecture.
- **Formal Verification**: Tools to mathematically prove the safety of a `.sgvm` binary before execution (as mentioned in `SPEC.md`).
- **Bytecode Verifier**: Pre-execution verification for constant references and jump targets in `MetalVM` (restoration of missing functionality).
- **AST Delegation**: Full implementation of `OP_EXEC_AST_STMT` to allow execution of non-lowered code via `sys.exec()`.
