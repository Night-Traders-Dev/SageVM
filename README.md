# SageVM: Unified Virtual Machine Substrate

![SageVM Header Banner](assets/sagevm.png)

SageVM is a high-performance, pure SageLang implementation of the Sage Virtual Machine. It provides a portable execution substrate for SageOS, supporting both a traditional stack-based architecture (SVM) and a modern RISC-V register-based architecture (SRVM).

## Status (v1.0.0 GA)

| Component | Compile | Execute | Self-Host | Coverage Suite |
|-----------|---------|---------|-----------|----------------|
| **SVM** (Stack VM / `.sgvm`) | ✅ | ✅ | ✅ | **100% (79/79 PASS)** |
| **SRVM** (RISC-V Register VM / `.sgrv`) | ✅ | ✅ | — | **Pass** |

- **SVM** is fully self-hosting and verified: `sagevm_standalone.sage` compiles to a `.sgvm` binary (~96 KB) and executes on the Stack VM. All 79 coverage test cases pass 100%.
- **SRVM** compilation & execution pipeline: Full SageLang source → SVM bytecode → RISC-V 32-bit instructions → `.sgrv` binary (~199 KB) execution with RV64I register file semantics.

## Features

- **Dual-Architecture Engine**: Seamlessly switch between Stack VM (SVM) and RISC-V Register VM (SRVM) targets.
- **Self-Hosted Compilation**: The SageVM compiler is written in SageLang and compiles itself via the Stack VM — a true bootstrap.
- **100% Test & Opcode Coverage**: 79/79 coverage tests passing cleanly across all 92 opcodes including generators, GPU hot-paths, local variable access, and exception handling.
- **Native Generator Yield Engine**: Native SVM state preservation for `OP_YIELD`, `OP_CREATE_GENERATOR`, and `OP_GENERATOR_NEXT` / `next()`.
- **RISC-V Translation**: Full `StackToRiscVTranslator` pipeline converts SVM bytecode to RV64I-compatible 32-bit fixed-width instructions.
- **OOP & Exceptions**: Native support for classes, inheritance, and `try/catch/finally` across both architectures.
- **Delegation Bridge**: Guest-to-host delegation for GPU, I/O, FFI, and native modules.
- **Matrix Visualization**: Native `math.printm` support for formatted matrix output.
- **Security Sandboxing**: `--safe`, `--no-exec`, and `--no-ffi` flags for restricting guest execution.
- **Unified CLI**: A single `sagevm` tool to compile, run, disassemble, and hexdump both `.sgvm` and `.sgrv` binaries with ANSI color feedback and automatic architecture detection.

## Installation

SageVM requires SageLang **v4.1.2** or higher. To build and install:

```bash
./sagemake --install
```

This produces the `sagevm` binary (and symlinks for `sgvm`/`sgvmc`).

To build without installing:

```bash
./sagemake build
```

## Unified CLI (sagevm)

```
sagevm run <file.sgvm|.sgrv> [--debug] [--safe] [--no-exec] [--no-ffi] [--riscv] [--jit]
sagevm compile <file.sage> [output] [--shebang] [--riscv]
sagevm dis <file.sgvm|.sgrv> [--sage | --svm] [--riscv]
sagevm hex <file.sgvm|.sgrv> [--riscv]
sagevm repl [--riscv | --svm] [--debug] [--safe] [--jit]
sagevm version
```

- **run**: Execute a compiled binary. Auto-detects architecture via magic headers (`SGVM` / `SGRV`).
- **compile**: Compile SageLang source to binary. Use `--riscv` for register-based `.sgrv` output.
- **dis**: Disassemble binary into readable instructions. Auto-detects architecture.
- **hex**: Low-level binary hexdump. Auto-detects architecture.
- **repl**: Launch interactive REPL executing input lines directly on SRVM (RISC-V) or SVM (Stack VM) substrates.

## Architectures

### 1. SVM (Stack Virtual Machine)

The core SGVM architecture. Uses variable-length bytecode and a 65,536-entry operand stack. Optimized for code density and simple compiler targets.

- **Opcode count**: 92 (including locals, generators, GPU hot-paths)
- **Call depth**: 1,024 frames
- **Handler depth**: 1,024 levels
- **Performance**: Fully inlined hot-loop dispatch with state caching, single/two-scope global fast-paths, and in-place stack modification

### 2. SRVM (Sage RISC-V Virtual Machine)

A modern, register-based architecture based on the **RV64I** specification.

- **32 × 64-bit registers**: Standard RISC-V register file mapping (x0–x31)
- **Fixed-width encoding**: 32-bit instructions for simplified decoding
- **Custom VMSYS extensions**: `OP_VMSYS` for SageVM system calls, object operations, and GPU delegation
- **Type profiling**: `TypeProfiler` for register-level type hint analysis
- **Performance**: Up to 30–40% faster interpretation for arithmetic-heavy code

## Recent Changes (v1.0.0 GA)

### 100% Test Coverage & Opcode Conformance
- **Opcode Hex Translation Alignment**: Aligned host 0-based bytecode indices (`0x3b` for `BC_OP_GET_LOCAL`, `0x3c` for `BC_OP_SET_LOCAL`, `0x3a` for `BC_OP_RAISE`) to VM opcode layout in `sgvm_compiler.sage`.
- **Native Generator Yield Engine**: Implemented native SVM state preservation for `OP_CREATE_GENERATOR`, `OP_YIELD`, and `OP_GENERATOR_NEXT` / `next()`.
- **Script Chunk Reset**: Updated `SGVMRunner` and `MetalVM` to handle multi-chunk script execution and `sys.exit()` signal isolation.
- **Security Sandboxing**: Hardened `safe_mode` object modification protections for `push`/`pop` on protected dictionaries.
- **Full Test Suite Conformance**: **79/79 tests passed (100% pass rate)**.

### Security & Correctness
- **SRVM register spilling**: Fixed silent data corruption beyond 8 temporary registers
- **SRVM unsigned operations**: Fixed SRLI/SRAI and BLTU/BGEU instruction semantics
- **SVM builtin parity**: Added 16 missing builtins (push, pop, chr, ord, startswith, endswith, etc.)
- **`--no-exec` flag**: Disable `OP_EXEC_AST_STMT` independently of safe mode
- **Hardened byte writing**: `sage_io_writebytes` supports both `SAGE_TAG_BYTES` and `SAGE_TAG_ARRAY`

## Performance Benchmarks

| Benchmark | SVM (ms) | SRVM (ms) | Improvement |
|-----------|----------|-----------|-------------|
| `fibonacci(22)` | 2256 | 1580 | 30% |
| `loop_sum` | 4513 | 3120 | 31% |
| `exception_handling` | 417 | 290 | 30% |

*Benchmarks reflect interpretation overhead in a pure SageLang environment.*

## Documentation

- [Architecture](docs/ARCHITECTURE.md) — Technical details of SVM and SRVM execution substrates
- [Specification](docs/SPEC.md) — Formal specification of binary formats and execution
- [RISC-V Design](docs/rv64.md) — Deep dive into the SRVM register-based design
- [Changelog](docs/CHANGELOG.md) — Full version history
- [Roadmap](docs/ROADMAP.md) — Outstanding features and known gaps

## License

This project is licensed under the same terms as SageLang.
