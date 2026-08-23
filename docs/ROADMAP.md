# SageVM Roadmap

This document outlines the current status, supported features, and outstanding work items for SageVM.

## ✅ Fully Supported

- **Stack VM Self-Hosting**: `sagevm_standalone.sage` compiles to `.sgvm` and executes — SageVM compiles itself via the Stack VM.
- **RISC-V Compilation Pipeline**: Full `.sage` → `.sgrv` translation via `StackToRiscVTranslator` (compilation verified, runtime WIP).
- **Floating Point Binary Loading**: Full IEEE 754 64-bit double support for packing and unpacking.
- **Exception Handling**: Full support for `try/catch/finally` with correct call stack and scope unwinding.
- **Enhanced Flow Control**: Correct handling of relative jumps, `OP_BREAK`, `OP_CONTINUE`, `OP_LOOP_BACK`.
- **Dynamic Imports**: Ability to load and execute external `.sgvm` modules at runtime.
- **Native Bridging Layer**: Support for `math`, `io`, `sys`, `net`, `gpu`, and `ml_native` modules via host SageLang mapping.
- **Multi-threading**: Full support for `thread` module with a Global Interpreter Lock (GIL) and result capturing.
- **Resource Management**: Guest memory tracking and enforcement via host-provided limits.
- **GPU Hot-Paths**: Implementation of `BC_OP_GPU_*` opcodes (59–86) for Vulkan/OpenGL acceleration via host delegation; stub handlers for headless environments.
- **AST Delegation**: Full implementation of `OP_EXEC_AST_STMT` to allow execution of non-lowered code via `sys.exec()`.
- **Matrix Visualization**: Native interpretation for `OP_MATH_PRINTM`.
- **Native Bridge Modules**: `ffi` (with `sage_ffi_call` and `sage_ffi_call_full` native calling and type marshaling), `mem`, and `struct` native modules exposed to guest VM.
- **Security Sandboxing**: `safe_mode`, `ffi_enabled`, `exec_enabled` flags with `--safe`, `--no-ffi`, `--no-exec` CLI flags.
- **SVM Builtin Parity**: All 16 string/collection builtins (`push`, `pop`, `chr`, `ord`, `startswith`, `endswith`, `contains`, `join`, `split`, `replace`, `upper`, `lower`, `strip`, `dict_has`, `dict_keys`, `dict_values`).
- **MetalVM Spec Conformance**: Truthiness (only `nil`/`false`/`0` falsy), deep equality, string repetition, division-by-zero → `nil`.
- **Local Variable Opcodes**: `OP_GET_LOCAL` (88) and `OP_SET_LOCAL` (89) implemented in SVM interpreter.
- **SRVM Sandboxing**: `safe_mode`, `no_ffi`, and `exec_enabled` enforcement for the RISC-V backend, including `sys.exec`/`sys.system`/AST-execution restriction handlers.
- **JIT/AOT Foundation**: Initial components (Memory Manager, RISC-V Emitter, Type Profiler) and OSR hooks implemented in `src/jit/` and `src/srvm/`.

- **SVM Generator Engine**: Full native VM implementation for `OP_CREATE_GENERATOR` (91), `OP_YIELD` (90), `OP_GENERATOR_NEXT` (92), and `next()` builtin.
- **Opcode Hex Translation Alignment**: Host 0-based bytecode opcodes aligned with SageVM execution layout across compiler and runner.
- **100% Coverage Pass Rate**: 113/113 coverage tests passing under Stack VM and RISC-V VM targets.

## 🟡 In Progress

- **SRVM Large Binary Dynamic Addressing**: Optimization for large-scale RISC-V constant pool resolution (>1,000 instructions).

## 🔴 Outstanding (Future Release Features)

- [ ] **Regex & JSON Native Modules**: Restore `re` and `json` guest module bridging in `src/svm/sgvm_vm.sage`.
- [ ] **SRVM GPU Implementation**: Implement register-based GPU opcodes in `src/srvm/srvm_vm.sage`.
- [ ] **SRVM Register Opcode Gaps**: Implement remaining register-based extensions (`VMO_CMP_BINARY`, `OBJ_SLICE`).
- [ ] **Disassembler Labels**: Add descriptive labels for local variable, generator, matrix, and GPU opcodes in disassembler output.
- [x] **Runner exec_enabled**: Thread `--no-exec` flag through SGVMRunner and SRVMRunner to MetalVM/SRVM.
- [ ] **OP_ARRAY_LEN on nil**: Resolve conformance gap where `OP_ARRAY_LEN` returns `0` on `nil` due to host inheritance instead of `nil` / error (see `tests/array_len_edge.sage`).
- [ ] **Guest sys.exit halting**: Ensure guest-side `sys.exit` completely halts execution flow across all multi-chunk VM runner configurations.
- [ ] **Safe-mode Exception Printing**: Align safe-mode exception printing and trace output format between SVM and host execution.

## 🔴 Outstanding (High Difficulty)

- [ ] **SVM Lexical Capture/Closures**: Implement support for lexical capture in the SVM interpreter to allow functions to access outer scope variables.
- [ ] **Networking**: Full implementation of `socket` and `http` modules.
- [ ] **Bytecode Verifier**: Pre-execution verification for constant pool integrity and jump target validity.
- [ ] **SRVM Deep Recursion**: SRVM currently has limited call stack depth for deep recursion (e.g., recursive Fibonacci > 20).

## 🟣 Research / Future

- [ ] **JIT/AOT Compilation**: Extend initial components into a working JIT compiler with on-stack replacement.
- [ ] **Formal Verification**: Tools to mathematically prove the safety of a `.sgvm` binary before execution.
- [ ] **SRVM Self-Hosting**: Achieve full `.sgrv` runtime parity to enable SRVM self-hosting.
