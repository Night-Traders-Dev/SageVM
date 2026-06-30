# SGVM & SGRV Specification

## 1. Overview
The Sage Virtual Machine (SGVM) is the portable execution substrate for SageOS. It supports two execution backends:
- **SVM**: Traditional Stack Virtual Machine.
- **SRVM**: RISC-V 64-bit Register Virtual Machine.

---

## 2. Binary Formats

### 2.1 SVM Format (.sgvm)
1. **Header**: "SGVM" (4 bytes).
2. **Version**: 2 bytes.
3. **Function Count**: 2 bytes (big-endian).
4. **Constant Pool**: Count + Entries.
5. **Chunk Count**: 4 bytes (big-endian).
6. **Chunks**: Length (4 bytes) + Code (Variable length).

### 2.2 SGRV Format (.sgrv)
1. **Header**: "SGRV" (4 bytes).
2. **Version**: 2 bytes.
3. **Constant Pool**: Count + Entries.
4. **Chunk Count**: 4 bytes (big-endian).
5. **Chunks**: Length (4 bytes) + Fixed-width 32-bit instructions.

### 2.3 Diagnostic Tooling
Both formats are fully supported by the unified SageVM CLI tools, which utilize 4-byte magic header inspection for automatic architecture detection:
- `sagevm dis`: Disassembles both stack and register-based binaries.
- `sagevm hex`: Provides a low-level structural view of both binary formats.

---

## 3. Compilation & Execution Pipeline
SageLang code follows a strictly defined path to execution:
1. **Source**: Human-readable `.sage` files.
2. **Compiler Frontend**: Parses source into an Abstract Syntax Tree (AST) or Intermediate Representation (SGIR).
3. **Bytecode Generation**: Emits portable SGVM instructions. For register-based targets, performs translation to SGRV.
4. **Verification**: Mandatory security and safety checks.
5. **Runtime Execution**: Execution by the MetalVM (SVM) or MetalRV64 (SRVM) engine. The execution loop is optimized through inlining and caching of critical properties (stack pointer, max stack depth) to reduce per-instruction overhead.

## 4. Execution Semantics

### 4.1 Truthiness
In the SageVM implementation, truthiness follows strict rules for boolean context evaluation (e.g., `OP_JUMP_IF_FALSE`, `OP_TRUTHY`):
- **Falsy**: `0` (number), `nil`, `false`.
- **Truthy**: `true`, non-zero numbers, empty/non-empty strings (""), empty/non-empty arrays ([]), and empty/non-empty dictionaries ({}).

*Note: While standard SageLang may treat empty collections as falsy, the current `MetalVM` implementation erroneously treats empty strings as falsy by inheriting host SageLang behavior. This is a documented conformance bug.*

## 5. Bytecode Verification & Runtime Safety
(Note: Full static bytecode verification is currently a roadmap item for the SageLang-based interpreter. Runtime enforcement is currently used to ensure safety.)

Before and during execution, production SGVM bytecode MUST pass verification and runtime checks that ensure:
- **Control Flow Integrity**: No illegal jumps; recursive depth is limited to 1,024 frames (`max_call_depth`).
- **Type Safety**: Operations are performed on valid operand types.
- **Boundary Checks**: No out-of-bounds access to memory or object arenas. Execution state is accelerated by caching `current_local_base` for local variable access.
  - **SVM**: Operand stack depth is limited to 65,536 entries (`max_stack_depth`). Exception handler nesting is limited to 1,024 levels (`max_handler_depth`).
  - **SRVM**: The fixed stack area is initialized with 1,000 slots. Recursive call depth and exception handler nesting are limited to 1,024 frames. Max array size is 1,000,000 entries.
- **Path Sanitization**: Compiler validates input and output file paths against shell metacharacters to prevent command injection.
- **Capability Access**: The bytecode does not attempt to use restricted syscalls without proper permissions.
- **Internal State Protection**: In `safe_mode`, runtime enforcement blocks all property and index access for identifiers starting with `__` (excluding the `__arg` prefix). This ensures that internal descriptors like `__host_mod__`, `__builtin__`, and `__type__` remain inaccessible to guest code, preventing sandbox escapes and internal state inspection.

## 6. Execution Modes
SGVM supports multiple execution strategies:
- **Interpreted**: Direct execution of the AST or bytecode (default for kernel-mode scripts). Interpreters are optimized with inlined fetch-decode-execute loops and local variable caching (`current_local_base`) to minimize guest overhead.
- **Threaded Interpreter**: High-performance bytecode dispatching using labels-as-values.
- **JIT/AOT (Future)**: Just-in-Time or Ahead-of-Time compilation to native machine code for performance-critical applications.

## 7. MetalVM C API (`metal_vm.h`)
The kernel interacts with SGVM via the following internal interfaces:
- `metal_vm_load_binary()`: Loads a compiled `.sgvm` artifact into memory.
- `metal_vm_run()` / `metal_vm_step()`: Executes bytecode instructions.
- `metal_vm_register_native()`: Binds kernel-level functions to SageLang (implemented via the **Native Bridge** in the SageLang-based interpreter).
- `sage_gil_acquire()` / `sage_gil_release()`: Serializes access to the VM state to maintain thread safety in SMP environments.

## 8. Object System & GC
SGVM features a reference-tracked object system with a built-in Mark-and-Sweep garbage collector. Objects (primarily Arrays and Dictionaries) are capability-tagged and reside in dedicated memory arenas.

---

## 9. Opcode Conformance

**Last Conformance Sync: 2026-06-30**

### 9.1 SageVM Extensions
The following opcodes are SageVM-specific extensions or legacy mappings:
- `OP_MATH_PRINTM` (87): Native matrix visualization (Collides with authoritative `BC_OP_GPU_CMD_PUSH_CONST`).
- `OP_GET_LOCAL` (88): Get a local variable value (Collides with authoritative `BC_OP_GPU_CMD_DISPATCH`).
- `OP_SET_LOCAL` (89): Set a local variable value (Authoritative index is 60).
- `OP_HALT` (255): Unconditional VM termination.

### 9.2 Known Incompatibilities
- **Opcode Alignment Regression**: As of the latest sync, the authoritative `bytecode.h` has introduced `BC_OP_GET_LOCAL` (59) and `BC_OP_SET_LOCAL` (60), which has shifted the entire GPU instruction block (indices 61-88). SageVM currently maintains a legacy mapping where GPU opcodes start at 59, leading to a 2-opcode shift across the entire Phase 16 instruction set and collisions for trailing SageVM-specific opcodes.
- **GPU Instruction Set (SRVM)**: The register-based VM (SRVM) utilizes a legacy 2D GPU instruction set that differs significantly from the Vulkan-aligned opcodes in the core spec.
- **Raise Encoding**: Historically, the `sgvmc` compiler (SVM) expected an incorrect encoding (`0x44`) for `OP_RAISE` which conflicted with `OP_GPU_END_COMMANDS`. This was resolved in v0.9.7; `OP_RAISE` is now correctly mapped to 58. Note that `sgvmc` still contains a hazardous legacy remapping for `0x44` -> 58.
