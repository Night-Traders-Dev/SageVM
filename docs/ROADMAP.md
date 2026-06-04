# SGVM Roadmap: Unsupported Features

This document outlines the features and standard library modules currently unsupported by the SGVM interpreter (`sgvm.sage`). Tasks are categorized by their implementation difficulty.

## ✅ Supported Features
- **Floating Point Binary Loading**: Full IEEE 754 64-bit double support for packing and unpacking.
- **Exception Handling**: Full support for `try/catch/finally` via `SETUP_TRY`, `END_TRY`, and `RAISE`.
- **Enhanced Flow Control**: Correct handling of relative jumps and loop control opcodes.
- **Dynamic Imports**: Ability to load and execute external `.sgvm` modules at runtime.

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
