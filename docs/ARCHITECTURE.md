# SageVM Architecture

SageVM implements a dual-VM architecture, supporting both a traditional stack-based virtual machine (SVM) and a register-based virtual machine (SRVM).

## 1. SVM (Stack Virtual Machine - Legacy/Core)
The traditional SGVM architecture optimized for code density. Uses variable-length bytecode and a stack-based operand model. This is the primary target for initial compilation from SageLang source.

## 2. SRVM (RISC-V Register Virtual Machine - Modern/High-Performance)
A modern, register-based architecture mapped to the RV64I specification. This VM is the target for the AOT/JIT compilation pipeline, providing superior performance and easier mapping to native hardware instructions (RISC-V, x86_64, ARM64).

- **Register File**: 32 x 64-bit general-purpose registers (x0-x31).
- **Instruction Encoding**: Fixed 32-bit width for efficient decoding.
- **Addressing**: Load-Store architecture separating computation from memory.

## 3. Unified Diagnostic Pipeline
To support the ongoing development of both architectures, SageVM provides a unified diagnostic pipeline. The `sagevm` CLI automatically detects the target architecture by inspecting the 4-byte magic header of the binary.

- **SGVM (Stack)**: Magic `SGVM`. Disassembled into high-level `.sage`-like pseudo-code or low-level `.svm` bytecode.
- **SGRV (RISC-V)**: Magic `SGRV`. Disassembled into standard RISC-V assembly with custom SageVM system extensions (`ldc`, `vm_nop`, etc.).

The CLI provides colorized feedback (Red for errors, Green for success, Yellow for tips, Cyan for headers) to improve scannability and offers helpful tips when users attempt to use binary tools on source files.

This pipeline ensures that developers can inspect the low-level structure of their compiled programs regardless of the target architecture.

---

## 4. Execution Substrates

### 4.1 MetalVM (Stack-Based)
The core SVM implementation in `src/svm/sgvm_vm.sage`. It utilizes an operand stack for all computations.

- **Stack Capacity**: 65,536 entries.
- **Call Depth**: 1,024 frames.
- **Handler Depth**: 1,024 levels.
- **Performance Optimizations**:
  - **Inlined Loop**: The instruction decoding, BE16 decoding, and operand fetching logic is inlined into the main `run` loop to minimize function call and property lookup overhead.
  - **State Caching**: The VM caches critical state (operand stack, constant pool) in local variables within the execution loop, yielding a ~4.3x speedup in loop-heavy benchmarks.
  - **Local Base Caching**: The VM caches `current_local_base` to accelerate `OP_GET_LOCAL` and `OP_SET_LOCAL` by avoiding repeated call stack traversals.

### 4.2 MetalRV64 (Register-Based)
The SRVM implementation in `src/srvm/srvm_vm.sage`. It maps guest execution to a virtual RISC-V 64-bit hardware model.

- **Register File**: x0 (zero) through x31.
- **Stack Area**: 1,000 fixed slots.
- **Call Depth**: 1,024 frames.
- **Handler Depth**: 1,024 levels.
- **Max Array Size**: 1,000,000 entries.
- **Optimized Builtins**: Provides native implementations for string and collection utilities.
- **Performance Optimizations**:
  - **Lean Interpreter**: Removed legacy JIT hot-path detection stubs and string concatenations from the fetch-decode loop, yielding ~60% speedup in arithmetic-heavy code.

(Refer to `SPEC.md` for the complete opcode table.)

### Custom VMSYS Opcodes
SRVM uses `OP_VMSYS` (standard RISC-V SYSTEM opcode repurposed) to access SageVM-specific system functionality. The specific operation is determined by the `funct7` field:

- **funct3 = 000 (VM Operations)**:
  - `0x00`: NOP
  - `0x01`: HALT
  - `0x02`: PUSH_ENV
  - `0x03`: POP_ENV
  - `0x04`: CALL
  - `0x05`: SETUP_TRY
  - `0x06`: END_TRY
  - `0x07`: RAISE
  - `0x08`: IMPORT
  - `0x09`: PRINT
  - `0x0A`: ARRAY_LEN
  - `0x0B`: PRINTM
  - `0x0C`: EXEC_AST
  - `0x0D`: CMP_BINARY

- **funct3 = 001 (GPU Operations)**:
  - `0x00`: GPU_POLL_EVENTS
  - `0x01`: GPU_WINDOW_SHOULD_CLOSE
  - `0x02`: GPU_GET_TIME
  - `0x03`: GPU_KEY_PRESSED
  - `0x04`: GPU_MOUSE_PRESSED
  - `0x05`: GPU_MOUSE_POS
  - `0x06`: GPU_SCREEN_SIZE
  - `0x07`: GPU_CLEAR
  - `0x08`: GPU_SET_COLOR
  - `0x09`: GPU_DRAW_PIXEL
  - `0x0A`: GPU_DRAW_LINE
  - `0x0B`: GPU_DRAW_RECT
  - `0x0C`: GPU_DRAW_CIRCLE
  - `0x0D`: GPU_DRAW_TRIANGLE
  - `0x0E`: GPU_DRAW_TEXT
  - `0x0F`: GPU_LOAD_IMAGE
  - `0x10`: GPU_DRAW_IMAGE
  - `0x11`: GPU_LOAD_FONT
  - `0x12`: GPU_LOAD_SOUND
  - `0x13`: GPU_PLAY_SOUND
  - `0x14`: GPU_STOP_SOUND
  - `0x15`: GPU_LOAD_MUSIC
  - `0x16`: GPU_PLAY_MUSIC
  - `0x17`: GPU_STOP_MUSIC
  - `0x18`: GPU_CMD_BATCH_BEGIN
  - `0x19`: GPU_CMD_BATCH_END
  - `0x1A`: GPU_CMD_DISPATCH
  - `0x1B`: GPU_BUFFER_CREATE
  - > ⚠️ **Encoding Mismatch**: SRVM currently utilizes a legacy 2D-accelerated GPU instruction set (0x00-0x1B) which is incompatible with the Vulkan-like `BC_OP_GPU_*` opcodes defined in the authoritative `bytecode.h`.

- **funct3 = 010 (Object Operations)**:
  - `0x00`: GET_GLOBAL
  - `0x01`: SET_GLOBAL
  - `0x02`: NEW_CLASS
  - `0x03`: INHERIT
  - `0x04`: METHOD_BIND
  - `0x05`: GET_PROP
  - `0x06`: SET_PROP
  - `0x07`: NEW_FUNC
  - `0x08`: ARRAY_NEW
  - `0x09`: DICT_NEW
  - `0x0A`: TUPLE_NEW
  - `0x0B`: GET_INDEX
  - `0x0C`: SET_INDEX
  - `0x0D`: SLICE

---

## 5. Bytecode Opcodes

**Last Conformance Sync: 2026-07-13**

> ⚠️ **Opcode Alignment Regression**: As of the latest sync, a critical encoding mismatch persists and has expanded. The authoritative `bytecode.h` has introduced `BC_OP_GET_LOCAL` (59), `BC_OP_SET_LOCAL` (60), `BC_OP_YIELD` (61), `BC_OP_CREATE_GENERATOR` (62), and `BC_OP_GENERATOR_NEXT` (63), shifting the entire GPU instruction block to indices 64-91. SageVM currently maintains a legacy mapping (59-86 for GPU), resulting in a **5-opcode shift** for the Phase 16 block and multiple collisions for SageVM-specific extensions (e.g., `OP_YIELD` at 90 vs. authoritative 61).

> ⚠️ **Disassembler Logic Gap**: The SVM disassembler (`src/svm/sgvm_disassembler_logic.sage`) currently lacks descriptive labels for local variable (88-89), generator (90-92), matrix (87), and GPU (59-86) opcodes, displaying them as `unknown_N` in disassembled output.

> ⚠️ **Compiler Implementation Gap**: `sgvmc` (`src/svm/sgvm_compiler.sage`) currently lacks binary emission logic for `OP_MATH_PRINTM` (87). Local variable opcodes (88-89) are now correctly remapped in the compiler's second pass, but they diverge from the new authoritative indices (59-60).

The following opcodes are supported by `sgvm.sage` and emitted by `sgvmc.sage`.

| Opcode | Value | Auth. Index | Description |
|--------|-------|-------------|-------------|
| OP_CONSTANT | 0 | 0 | Push a constant onto the stack |
| OP_NIL | 1 | 1 | Push nil onto the stack |
| OP_TRUE | 2 | 2 | Push true onto the stack |
| OP_FALSE | 3 | 3 | Push false onto the stack |
| OP_POP | 4 | 4 | Pop the top value from the stack |
| OP_GET_GLOBAL | 5 | 5 | Get a global variable value |
| OP_DEFINE_GLOBAL | 6 | 6 | Define a global variable |
| OP_SET_GLOBAL | 7 | 7 | Assign a value to a global variable |
| OP_DEFINE_FUNCTION | 8 | 8 | Define a function |
| OP_GET_PROPERTY | 9 | 9 | Get an object property |
| OP_SET_PROPERTY | 10 | 10 | Set an object property |
| OP_GET_INDEX | 11 | 11 | Get an element at an index (array/dict) |
| OP_SET_INDEX | 12 | 12 | Set an element at an index |
| OP_LOAD_FUNCTION | 13 | 13 | Load a function onto the stack |
| OP_SLICE | 14 | 14 | Perform an array or string slice |
| OP_ADD | 15 | 15 | Addition |
| OP_SUB | 16 | 16 | Subtraction |
| OP_MUL | 17 | 17 | Multiplication |
| OP_DIV | 18 | 18 | Division |
| OP_MOD | 19 | 19 | Modulo |
| OP_NEGATE | 20 | 20 | Unary negation |
| OP_EQUAL | 21 | 21 | Equality check |
| OP_NOT_EQUAL | 22 | 22 | Inequality check |
| OP_GREATER | 23 | 23 | Greater than |
| OP_GREATER_EQUAL | 24 | 24 | Greater than or equal |
| OP_LESS | 25 | 25 | Less than |
| OP_LESS_EQUAL | 26 | 26 | Less than or equal |
| OP_BIT_AND | 27 | 27 | Bitwise AND |
| OP_BIT_OR | 28 | 28 | Bitwise OR |
| OP_BIT_XOR | 29 | 29 | Bitwise XOR |
| OP_BIT_NOT | 30 | 30 | Bitwise NOT |
| OP_SHIFT_LEFT | 31 | 31 | Bitwise left shift |
| OP_SHIFT_RIGHT | 32 | 32 | Bitwise right shift |
| OP_NOT | 33 | 33 | Logical NOT |
| OP_TRUTHY | 34 | 34 | Truthiness check |
| OP_JUMP | 35 | 35 | Unconditional jump |
| OP_JUMP_IF_FALSE | 36 | 36 | Jump if the top value is false |
| OP_CALL | 37 | 37 | Call a function |
| OP_CALL_METHOD | 38 | 38 | Call an object method |
| OP_ARRAY | 39 | 39 | Create an array |
| OP_TUPLE | 40 | 40 | Create a tuple |
| OP_DICT | 41 | 41 | Create a dictionary |
| OP_PRINT | 42 | 42 | Print a value |
| OP_EXEC_AST_STMT | 43 | 43 | Execute an AST statement (fallback) |
| OP_RETURN | 44 | 44 | Return from a function |
| OP_PUSH_ENV | 45 | 45 | Push a new environment scope |
| OP_POP_ENV | 46 | 46 | Pop an environment scope |
| OP_DUP | 47 | 47 | Duplicate a value on the stack |
| OP_ARRAY_LEN | 48 | 48 | Get array length |
| OP_BREAK | 49 | 49 | Loop break |
| OP_CONTINUE | 50 | 50 | Loop continue |
| OP_LOOP_BACK | 51 | 51 | Jump to the start of a loop |
| OP_IMPORT | 52 | 52 | Import and execute an external module |
| OP_CLASS | 53 | 53 | Define a class |
| OP_METHOD | 54 | 54 | Define a method on a class |
| OP_INHERIT | 55 | 55 | Set up class inheritance |
| OP_SETUP_TRY | 56 | 56 | Push an exception handler |
| OP_END_TRY | 57 | 57 | Pop the current exception handler |
| OP_RAISE | 58 | 58 | Raise an exception |
| OP_GPU_POLL_EVENTS | 59 | 64 | gpu.poll_events() [Collision: GET_LOCAL] |
| OP_GPU_WINDOW_SHOULD_CLOSE | 60 | 65 | gpu.window_should_close() [Collision: SET_LOCAL] |
| OP_GPU_GET_TIME | 61 | 66 | gpu.get_time() -> number [Collision: YIELD] |
| OP_GPU_KEY_PRESSED | 62 | 67 | gpu.key_pressed(key) -> bool [Collision: CREATE_GEN] |
| OP_GPU_KEY_DOWN | 63 | 68 | gpu.key_down(key) -> bool [Collision: GEN_NEXT] |
| OP_GPU_MOUSE_POS | 64 | 69 | gpu.mouse_pos() -> dict{x,y} |
| OP_GPU_MOUSE_DELTA | 65 | 70 | gpu.mouse_delta() -> dict{x,y} |
| OP_GPU_UPDATE_INPUT | 66 | 71 | gpu.update_input() |
| OP_GPU_BEGIN_COMMANDS | 67 | 72 | gpu.begin_commands(cmd) |
| OP_GPU_END_COMMANDS | 68 | 73 | gpu.end_commands(cmd) |
| OP_GPU_CMD_BEGIN_RP | 69 | 74 | gpu.cmd_begin_render_pass(cmd, rp, fb, w, h, clear) |
| OP_GPU_CMD_END_RP | 70 | 75 | gpu.cmd_end_render_pass(cmd) |
| OP_GPU_CMD_DRAW | 71 | 76 | gpu.cmd_draw(cmd, verts, inst, first_v, first_i) |
| OP_GPU_CMD_BIND_GP | 72 | 77 | gpu.cmd_bind_graphics_pipeline(cmd, pipe) |
| OP_GPU_CMD_BIND_DS | 73 | 78 | gpu.cmd_bind_descriptor_set(cmd, layout, set, bp) |
| OP_GPU_CMD_SET_VP | 74 | 79 | gpu.cmd_set_viewport(cmd, x, y, w, h, mind, maxd) |
| OP_GPU_CMD_SET_SC | 75 | 80 | gpu.cmd_set_scissor(cmd, x, y, w, h) |
| OP_GPU_CMD_BIND_VB | 76 | 81 | gpu.cmd_bind_vertex_buffer(cmd, buf) |
| OP_GPU_CMD_BIND_IB | 77 | 82 | gpu.cmd_bind_index_buffer(cmd, buf) |
| OP_GPU_CMD_DRAW_IDX | 78 | 83 | gpu.cmd_draw_indexed(cmd, idx_count, ...) |
| OP_GPU_SUBMIT_SYNC | 79 | 84 | gpu.submit_with_sync(cmd, wait, signal, fence) |
| OP_GPU_ACQUIRE_IMG | 80 | 85 | gpu.acquire_next_image(sem) -> number |
| OP_GPU_PRESENT | 81 | 86 | gpu.present(sem, img_idx) |
| OP_GPU_WAIT_FENCE | 82 | 87 | gpu.wait_fence(fence, timeout) [Collision: PRINTM] |
| OP_GPU_RESET_FENCE | 83 | 88 | gpu.reset_fence(fence) [Collision: GET_LOCAL] |
| OP_GPU_UPDATE_UNIFORM | 84 | 89 | gpu.update_uniform(handle, data) [Collision: SET_LOCAL] |
| OP_GPU_CMD_PUSH_CONST | 85 | 90 | gpu.cmd_push_constants(...) [Collision: YIELD] |
| OP_GPU_CMD_DISPATCH | 86 | 91 | gpu.cmd_dispatch(cmd, gx, gy, gz) [Collision: CREATE_GEN] |
| OP_MATH_PRINTM | 87 | - | math.printm(matrix) [Collision: WAIT_FENCE] |
| OP_GET_LOCAL | 88 | 59 | Get a local variable value [Collision: RESET_FENCE] |
| OP_SET_LOCAL | 89 | 60 | Set a local variable value [Collision: UPDATE_UNI] |
| OP_YIELD | 90 | 61 | Yield a value from generator [Collision: PUSH_CONST] |
| OP_CREATE_GENERATOR | 91 | 62 | Create a generator function [Collision: DISPATCH] |
| OP_GENERATOR_NEXT | 92 | 63 | Resume generator execution |
| OP_HALT | 255 | - | Halt execution [SageVM Extension] |

## Native Bridge

SGVM provides a high-performance native bridge to the host SageLang environment. This allows guest bytecode to call standard library functions directly without the overhead of guest-side implementations.

The following modules are currently bridged:
- **math**: Native SageLang `math` module (including `abs`, `sqrt`, `sin`, `cos`).
- **io**: Native SageLang `io` module.
- **sys**: Native SageLang `sys` module.
- **net**: Native SageLang `net` module (currently implemented via a shim in `src/svm/net.sage`).
- **thread**: Native SageLang `thread` module (host-level threading).
- **gpu**: Native SageLang `gpu` module (Vulkan/OpenGL acceleration).
- **ml_native**: Native SageLang `ml_native` module (Machine Learning acceleration).
- **ffi**: Foreign Function Interface for calling host C libraries.
- **mem**: Direct host memory management and raw access (including `alloc`, `free`, `read`, `write`, `size`).
- **struct**: Binary data structure packing/unpacking (including `def`, `new`, `get`, `set`, `size`).
- **gc**: (Experimental stub) Native SageLang garbage collector interface.
- **reflect**: (Experimental stub) Native SageLang reflection interface.

*Note: The `re` and `json` modules are not currently exposed through the guest-to-host bridge (see Roadmap).*

Native bridging is implemented by tagging objects and function-like dictionaries with a `__native__` property. The `OP_CALL` and `OP_CALL_METHOD` opcodes detect these tags and dispatch execution to the VM's `call_native()` handler.

## 6. Just-In-Time (JIT) Infrastructure

SageVM has begun laying the foundation for a high-performance JIT compilation pipeline located in `src/jit/`. This infrastructure aims to bridge the gap between interpreted bytecode and native hardware performance.

### 6.1 Executable Memory Management (`src/jit/jit_memory.sage`)
A dedicated manager for handling executable memory pages, implementing standard security practices:
- **W^X Enforcement**: Simulated Write XOR Execute protection to prevent simultaneous writing and execution of memory.
- **Page Transitions**: Controlled methods (`make_executable()`, `make_writable()`) for transitioning page permissions.
- **Security Guardrails**: Explicit checks to prevent writes to executable memory segments.

### 6.2 RISC-V Code Emitter (`src/jit/jit_emitter.sage`)
A low-level component responsible for translating the SRVM's RV64I Intermediate Representation (IR) into native machine instructions.
- **Instruction Generation**: Direct mapping of RV64I opcodes (e.g., `ADD`, `ADDI`) to binary instruction streams.
- **Memory Integration**: Tight coupling with the `ExecutableMemoryManager` for safe code emission into managed pages.

### 6.3 Type Profiler (`src/srvm/srvm_profiler.sage`)
A speculative optimization component that analyzes bytecode to infer data types for stack slots and local variables.
- **Speculative Analysis**: Infers types (Int, Float, Str, Obj) to enable optimized native code generation in the JIT pipeline.
- **Feedback Loop**: Provides type information to the code emitter for specialized instruction selection.

## Core Builtins

SGVM exposes several host-level functions directly in the global scope for performance and parity with the SageLang environment:

| Builtin | Description |
|---------|-------------|
| `clock()` | Returns the current system clock time. |
| `str(val)` | Converts a value to its string representation. |
| `int(val)` | Converts a value to an integer. |
| `tonumber(val)` | Converts a string to a number. |
| `len(obj)` | Returns the length of an array, dictionary, or string. |
| `print(val)` | Prints a value to standard output. |
| `range(n)` | Generates a range object from 0 to n-1. |
| `type(val)` | Returns the type name of a value. |
| `slice(obj, start, end)` | Creates a slice object or performs a slice on a string/array. |
| `gc_collect()` | Manually triggers garbage collection. |
| `gc_stats()` | Returns a dictionary with GC statistics. |
| `gc_enable()` / `gc_disable()` | Enables or disables the host garbage collector. |
| `reflect_get_methods(obj)` | Returns a list of method names available on an object (SVM-only). |
| `reflect_get_class(obj)` | Returns the class object for a given instance (SVM-only). |
| `push(arr, val)` | Pushes a value onto an array. |
| `pop(arr)` | Pops the last value from an array and returns it. |
| `chr(val)` | Converts an integer ASCII code to a character string. |
| `ord(str)` | Returns the integer ASCII code of the first character of a string. |
| `dict_has(d, key)` | Returns true if the dictionary contains the given key. |
| `dict_keys(d)` | Returns an array of keys in the dictionary. |
| `dict_values(d)` | Returns an array of values in the dictionary. |
| `startswith(str, prefix)` | Returns true if the string starts with the prefix. |
| `endswith(str, suffix)` | Returns true if the string ends with the suffix. |
| `contains(obj, val)` | Returns true if the array/string contains the value. |
| `join(arr, sep)` | Joins an array of strings with the separator. |
| `split(str, sep)` | Splits a string into an array by the separator. |
| `replace(str, old, new)` | Replaces occurrences of `old` with `new` in the string. |
| `upper(str)` / `lower(str)` | Converts a string to upper or lower case. |
| `strip(str)` | Removes leading and trailing whitespace from a string. |

*Note: String and collection utilities (push, pop, chr, ord, startswith, endswith, etc.) are currently implemented in the SRVM backend. They are identified gaps in the SVM interpreter (`sgvm_vm.sage`) and are planned for future restoration.*

## Multi-threading & GIL

SGVM supports true multi-threading by leveraging the host SageLang `thread` module. Each guest thread runs in its own `MetalVM` instance, sharing the same constant pool and global environment.

To maintain consistency within the SageLang-based interpreter, a **Global Interpreter Lock (GIL)** is used to serialize guest bytecode execution. The GIL is automatically released during blocking operations such as `thread.sleep()`, `thread.join()`, and `thread.lock()` to allow for maximum concurrency.

## Sandboxing & Isolation

For high-isolation environments, SGVM provides several security features implemented across both SVM and SRVM backends:
- **Resource Limits**: The host environment can enforce memory allocation limits on the guest VM.
- **Module Restriction & Guards**: Access to sensitive host modules is restricted in `safe_mode`.
  - **Deferred Initialization**: SVM (`MetalVM`) defers the population of sensitive host modules until after `safe_mode` has been configured, preventing race conditions or eager loading bypasses.
  - **Mutation Protection**: Guest code is prevented from mutating host modules or module wrappers via `is_protected(obj)` checks in property and index assignments.
  - **Builtin Protection**: SRVM enforces strict protection for objects tagged with `__builtin__`, ensuring core utility functions cannot be shadowed or corrupted in the guest environment.
- **Sandbox Hardening (Internal Properties)**: In `safe_mode`, both SVM and SRVM interpreters block property, index, and method access (via `OP_CALL_METHOD`) for all identifiers starting with `__` (except `__arg`), preventing guest code from inspecting internal VM state or leaking host bridge objects.
- **Internal Execution Limits**: To prevent Denial of Service (DoS) via resource exhaustion, the VM enforces the following internal limits:
  - **Maximum Stack Depth**: 65,536 (Maximum depth of the operand stack).
  - **Maximum Call Depth**: 1,024 (Maximum recursion depth for function calls).
  - **Maximum Handler Depth**: 1,024 (Maximum nesting depth for exception handlers).

## Function Arguments

Arguments to SGVM functions are passed positionally and bound to the function's local scope using the naming convention `__argN`, where `N` is the zero-based index of the argument. For example, the first argument is accessible as `__arg0`, the second as `__arg1`, and so on.

## Binary Format & I/O

SGVM uses a dedicated **BYTES** type for high-performance binary I/O, ensuring that bytecode and constants are parsed correctly across backends. The native `io.readbytes` bridge returns this type instead of a standard string, allowing for integer-based byte indexing.

The SGVM binary format consists of:
0. Optional Shebang: `#!/usr/bin/env sgvm\n` (added by `sgvmc --shebang`)
1. Header: "SGVM" (4 bytes)
2. Version: 0x01 0x00 (2 bytes)
3. Function Count: (2 bytes, big-endian) — Total number of function chunks.
4. Constant Pool:
   - Count (2 bytes, big-endian)
   - Constants (Type, then value)
5. Chunk Count: (4 bytes, big-endian) — Total number of chunks (including functions).
6. Chunks:
   - Length (4 bytes, big-endian)
   - Code (Byte array)
