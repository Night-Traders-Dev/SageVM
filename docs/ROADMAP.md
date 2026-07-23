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
- **Native Bridge Modules**: `ffi`, `mem`, and `struct` native modules exposed to guest VM.
- **Security Sandboxing**: `safe_mode`, `ffi_enabled`, `exec_enabled` flags with `--safe`, `--no-ffi`, `--no-exec` CLI flags.
- **SVM Builtin Parity**: All 16 string/collection builtins (`push`, `pop`, `chr`, `ord`, `startswith`, `endswith`, `contains`, `join`, `split`, `replace`, `upper`, `lower`, `strip`, `dict_has`, `dict_keys`, `dict_values`).
- **MetalVM Spec Conformance**: Truthiness (only `nil`/`false`/`0` falsy), deep equality, string repetition, division-by-zero → `nil`.
- **Local Variable Opcodes**: `OP_GET_LOCAL` (88) and `OP_SET_LOCAL` (89) implemented in SVM interpreter.
- **SRVM Sandboxing**: `safe_mode` and `no_ffi` enforcement for the RISC-V backend.
- **JIT/AOT Foundation**: Initial components (Memory Manager, RISC-V Emitter, Type Profiler) and OSR hooks implemented in `src/jit/` and `src/srvm/`.

## 🟡 In Progress

- **SRVM Runtime Execution**: `.sgrv` binaries compile successfully but large-binary execution has constant pool addressing issues (PC=4 lookup). Active debugging.
- **Opcode Index Conformance**: SageVM uses internal opcode indices (e.g., `GET_LOCAL`=88, `SET_LOCAL`=89) that differ from the authoritative `bytecode.h` indices (69, 70). Compiler remapping handles translation, but a full index realignment is planned.

## 🔴 Outstanding (Medium Difficulty)

- [ ] **Regex & JSON Support**: Restore `re` and `json` module bridging in `src/svm/sgvm_vm.sage`.
- [ ] **SVM Generator Implementation**: Full implementation for `OP_YIELD` (90), `OP_CREATE_GENERATOR` (91), `OP_GENERATOR_NEXT` (92) — currently stubs with error messages.
- [ ] **SRVM GPU Implementation**: Implement missing register-based GPU opcodes in `src/srvm/srvm_vm.sage`.
- [ ] **SRVM Opcode Gaps**: Implement missing register-based opcodes:
  - `VMO_NOP`, `VMO_IMPORT`, `VMO_EXEC_AST`, `VMO_CMP_BINARY`
  - `OBJ_NEW_CLASS`, `OBJ_INHERIT`, `OBJ_METHOD_BIND`, `OBJ_DICT_NEW`, `OBJ_TUPLE_NEW`, `OBJ_SLICE`
- [ ] **Disassembler Labels**: Add descriptive labels for local variable, generator, matrix, and GPU opcodes in disassembler output.
- [ ] **Runner exec_enabled**: Thread `--no-exec` flag through SGVMRunner and SRVMRunner to MetalVM/SRVM.

## 🔴 Outstanding (High Difficulty)

- [ ] **SVM Lexical Capture/Closures**: Implement support for lexical capture in the SVM interpreter to allow functions to access outer scope variables.
- [ ] **Networking**: Full implementation of `socket` and `http` modules.
- [ ] **Bytecode Verifier**: Pre-execution verification for constant pool integrity and jump target validity.
- [ ] **SRVM Deep Recursion**: SRVM currently has limited call stack depth for deep recursion (e.g., recursive Fibonacci > 20).

## 🟣 Research / Future

- [ ] **JIT/AOT Compilation**: Extend initial components into a working JIT compiler with on-stack replacement.
- [ ] **Formal Verification**: Tools to mathematically prove the safety of a `.sgvm` binary before execution.
- [ ] **SRVM Self-Hosting**: Achieve full `.sgrv` runtime parity to enable SRVM self-hosting.
