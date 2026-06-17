# SGVM Roadmap: Unsupported Features

This document outlines the features and standard library modules currently unsupported by the SGVM interpreter (`sgvm.sage`). Tasks are categorized by their implementation difficulty.

## ✅ Supported Features
- **Floating Point Binary Loading**: Full IEEE 754 64-bit double support for packing and unpacking.
- **Exception Handling**: Full support for `try/catch/finally` with correct call stack and scope unwinding.
- **Enhanced Flow Control**: Correct handling of relative jumps.
- **Dynamic Imports**: Ability to load and execute external `.sgvm` modules at runtime.
- **Native Bridging Layer**: Support for `math`, `io`, `sys`, `net`, `gpu`, and `ml_native` modules via host SageLang mapping.
- **Multi-threading**: Full support for `thread` module with a Global Interpreter Lock (GIL) and result capturing.
- **Resource Management**: Guest memory tracking and enforcement via host-provided limits.
- **GPU Hot-Paths**: Implementation of the `BC_OP_GPU_*` opcodes for Vulkan/OpenGL acceleration via host delegation.
- **AST Delegation**: [x] Full implementation of `OP_EXEC_AST_STMT` to allow execution of non-lowered code via `sys.exec()`.
- **Matrix Visualization**: [x] Native interpretation for `OP_MATH_PRINTM` (87) (Note: currently lacks `sgvmc` binary emission logic).
- **Native Bridge Modules**: [x] Re-implemented and exposed `ffi`, `mem`, and `struct` native modules to guest VM (restoration of missing functionality).
- **Security Sandboxing**: Implemented `safe_mode` and `ffi_enabled` flags to restrict access to sensitive native modules.

## 🟡 Medium Difficulty (Native Bridging)
- [ ] **Regex & JSON Support**: Restore `re` and `json` module bridging in `src/svm/sgvm_vm.sage`.
- [ ] **Local Variable Opcodes**: Implement interpreter support for `OP_GET_LOCAL` and `OP_SET_LOCAL` in `src/svm/sgvm_vm.sage`.
  - > ⚠️ **Encoding Mismatch**: Authoritative indices are 59 and 60, but SageVM currently uses stubs at 88 and 89.
- [ ] **Loop Control Opcodes**: Implement interpreter support for `OP_BREAK` (49) and `OP_CONTINUE` (50) in `src/svm/sgvm_vm.sage` (currently stubs).

## 🔴 High Difficulty (Complex Systems)
These tasks involve significant architectural additions or complex resource management.

- **Networking**: Full implementation of `socket` and `http` modules, requiring a safe abstraction of the host's networking stack.
- **Bytecode Verifier**: Pre-execution verification for constant pool integrity and jump target validity.
- **Recursion/Stack Depth**: 🟡 SRVM currently has limited call stack depth for deep recursion (e.g., recursive Fibonacci > 20).

## 🟣 Research / Future
- **JIT/AOT Compilation**: 🟡 Currently in progress (Phase 4: JIT Compilation Target). Infrastructure (Memory Manager, RISC-V Emitter) and OSR hooks implemented.
- **Formal Verification**: Tools to mathematically prove the safety of a `.sgvm` binary before execution (as mentioned in `SPEC.md`).
