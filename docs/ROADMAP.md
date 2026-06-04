# SGVM Roadmap: Unsupported Features

This document outlines the features and standard library modules currently unsupported by the SGVM interpreter (`sgvm.sage`). Tasks are categorized by their implementation difficulty.

## 🟢 Low Difficulty (Opcode Support)
These tasks primarily involve adding handlers to the `MetalVM.run` loop for existing opcodes defined in SageLang.

- **Floating Point Binary Loading**: Currently, the VM uses a placeholder for 64-bit doubles. Need to implement a proper byte-to-double conversion in `sgvm.sage`.
- **Exception Handling**: Implement `BC_OP_SETUP_TRY`, `BC_OP_END_TRY`, and `BC_OP_RAISE`. This requires adding an exception handler stack to the VM state.
- **Enhanced Flow Control**: Ensure full parity for `OP_BREAK`, `OP_CONTINUE`, and `OP_LOOP_BACK` across complex nested scopes.
- **Import Opcode**: Implement `BC_OP_IMPORT` to allow the VM to dynamically load and link additional `.sgvm` files at runtime.

## 🟡 Medium Difficulty (Native Bridging)
These tasks require implementing a "Native Bridge" to map SageLang standard library calls to the host environment's capabilities.

- **Math Module parity**: Map `math.sqrt`, `math.sin`, `math.cos`, etc., to the host SageLang's math functions.
- **Basic I/O Bridge**: Expose a restricted set of `io` operations (read/write) to the VM.
- **System Info**: Support `sys.args`, `sys.getenv`, and `sys.clock` by passing host information into the guest environment.
- **String Utilities**: Support native string operations like `find`, `replace`, and `regex` through native mapping rather than pure SageLang loops (performance optimization).

## 🔴 High Difficulty (Complex Systems)
These tasks involve significant architectural additions or complex resource management.

- **GPU Hot-Paths**: Implementation of the `BC_OP_GPU_*` opcodes for Vulkan/OpenGL acceleration. This requires a handle-based resource manager within the VM.
- **Multi-threading**: Implementing the SageLang `thread` module. This would require managing multiple VM states and a Global Interpreter Lock (GIL) within the SageLang-based interpreter.
- **Garbage Collection Optimization**: While SageLang handles memory, a dedicated "Guest GC" or capability-aware allocator might be needed for high-isolation environments.
- **FFI Support**: Allowing guest bytecode to call into host-system C libraries safely.
- **Networking**: Full implementation of `net`, `socket`, and `http` modules, requiring a safe abstraction of the host's networking stack.

## 🟣 Research / Future
- **JIT/AOT Compilation**: Transitioning from a pure interpreter to a system that emits native machine code for the target architecture.
- **Formal Verification**: Tools to mathematically prove the safety of a `.sgvm` binary before execution (as mentioned in `SPEC.md`).
