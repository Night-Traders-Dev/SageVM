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
- [x] **AST Delegation**: Full implementation of `OP_EXEC_AST_STMT` to allow execution of non-lowered code via `sys.exec()`.
- [x] **Matrix Visualization**: Native interpretation for `OP_MATH_PRINTM` (87) (Note: currently lacks `sgvmc` binary emission logic).
- [x] **Native Bridge Modules**: Re-implemented and exposed `ffi`, `mem`, and `struct` native modules to guest VM (including `mem.read`, `struct.def`, `math.sin/cos`, and `math.abs/sqrt` expansion).
- **Security Sandboxing**: Implemented `safe_mode` and `ffi_enabled` flags to restrict access to sensitive native modules.

## 🟡 Medium Difficulty (Native Bridging)
- [ ] **Regex & JSON Support**: Restore `re` and `json` module bridging in `src/svm/sgvm_vm.sage`.
- [x] **Local Variable Opcodes**: Implement interpreter support for `OP_GET_LOCAL` and `OP_SET_LOCAL` in `src/svm/sgvm_vm.sage`.
   - > ⚠️ **Encoding Mismatch**: Authoritative indices are 59 and 60, but SageVM currently uses indices 88 and 89.
- [ ] **Compiler Conformance**: Overhaul `src/svm/sgvm_compiler.sage` remapping logic to align with authoritative `bytecode.h` indices.
   - [ ] Local variable remapping (Update 88, 89 to 59, 60)
   - [ ] GPU opcode remapping (Align 59-86 with authoritative 61-88)
- [ ] **Loop Control Opcodes**: Implement interpreter support for `OP_BREAK` (49) and `OP_CONTINUE` (50) in `src/svm/sgvm_vm.sage` (currently stubs).
- [ ] **Local Variable Opcodes (Conformance)**: Implement `OP_GET_LOCAL` (59) and `OP_SET_LOCAL` (60) in `sgvm_vm.sage` to match authoritative indices.
- [ ] **SRVM GPU Implementation**: Implement missing register-based GPU opcodes in `src/srvm/srvm_vm.sage` to replace the legacy 2D instruction set.
- [x] **SRVM Sandboxing**: Implement `safe_mode` and `no_ffi` enforcement for the RISC-V backend to achieve parity with SVM security.
- [ ] **SVM Builtin Gaps**: Implement missing string/collection utilities (`push`, `pop`, `chr`, `ord`, `startswith`, `endswith`) in `src/svm/sgvm_vm.sage`.
- [ ] **Disassembler Label Gaps**: Implement descriptive labels for local variable (88-89), matrix (87), and GPU (59-86) opcodes in `src/svm/sgvm_disassembler_logic.sage`.
- [ ] **SRVM Opcode Gaps**: Implement missing register-based opcodes in `src/srvm/srvm_vm.sage`:
  - `VMO_IMPORT`, `VMO_EXEC_AST`
  - `OBJ_NEW_CLASS`, `OBJ_INHERIT`, `OBJ_METHOD_BIND`, `OBJ_DICT_NEW`, `OBJ_TUPLE_NEW`, `OBJ_SLICE`

## 🔴 High Difficulty (Complex Systems)
These tasks involve significant architectural additions or complex resource management.

- **Truthiness Conformance**: Resolve the bug in `src/svm/sgvm_vm.sage` where empty strings are erroneously treated as falsy (inherited from host SageLang) instead of truthy.
- **Networking**: Full implementation of `socket` and `http` modules, requiring a safe abstraction of the host's networking stack.
- **Bytecode Verifier**: Pre-execution verification for constant pool integrity and jump target validity.
- **Recursion/Stack Depth**: 🟡 SRVM currently has limited call stack depth for deep recursion (e.g., recursive Fibonacci > 20).

## 🟣 Research / Future
- [x] **JIT/AOT Compilation**: 🟢 Initial components (Memory Manager, RISC-V Emitter, Type Profiler) and OSR hooks implemented in `src/jit/` and `src/srvm/`.
- **Formal Verification**: Tools to mathematically prove the safety of a `.sgvm` binary before execution (as mentioned in `SPEC.md`).
