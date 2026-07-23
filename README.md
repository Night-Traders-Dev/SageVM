# SageVM: Unified Virtual Machine Substrate

![SageVM Header Banner](assets/sagevm.png)

SageVM is a high-performance, pure SageLang implementation of the Sage Virtual Machine (SGVM). It provides a portable execution substrate for SageOS, supporting both traditional stack-based and modern RISC-V register-based architectures.

## Features (v0.9.9)


## Recent Updates

- **v0.9.9 Security & Correctness Audit**: Comprehensive codebase audit resolving 7 critical, 9 high, and 12 medium issues.
- **Division-by-Zero Guards**: Added runtime guards for OP_DIV and OP_MOD in both SVM hot-path and fallback execution.
- **SRVM Register Spilling**: Fixed silent data corruption when expressions use more than 8 temporary registers.
- **SRVM Unsigned Operations**: Fixed SRLI/SRAI and BLTU/BGEU instruction semantics for RISC-V compliance.
- **String & Collection Builtins**: Added 16 missing builtins (push, pop, chr, ord, startswith, endswith, contains, join, split, replace, upper, lower, strip, dict_has, dict_keys, dict_values) to SVM for SRVM parity.
- **--no-exec Flag**: New CLI flag to disable OP_EXEC_AST_STMT without full safe mode.
- **Build System**: sagemake install now supports PREFIX env var and graceful sudo fallback.

- **Interpreter Hot-Loop Optimization**: Cleaned up the dispatch loop and restored missing `OP_TRUTHY` and `OP_PRINT` opcode branches.

- **Variable Caching & State Synchronization**: Corrected state synchronization logic for the new stack-based local variable caching mechanism in `MetalVM.run`.

- **Command Injection Prevention Fix**: Recompiled the VM using the updated SageLang `is_safe_command` validation logic to allow `sagevm compile` to properly parse spaces and single quotes when interacting with the host system.



- **Dual-Architecture Engine**: Seamlessly switch between Stack VM (SVM) and RISC-V Register VM (SRVM).
- **100% Opcode Parity**: Supports all 89 SVM opcodes and the standard RV64I base instruction set.
- **Delegation Bridge**: Full guest-to-host delegation for GPU, I/O, and native modules.
- **OOP & Exceptions**: Native support for classes, inheritance, and exception handling (`try/catch/finally`) across both architectures.
- **Matrix Visualization**: Native `math.printm` support for formatted matrix output.
- **Unified CLI**: A single tool to compile, run, and debug both `.sgvm` (stack) and `.sgrv` (RISC-V) binaries, featuring ANSI color feedback and automatic architecture detection.

## Installation

SageVM requires SageLang **v4.0.4** or higher. To build and install:

```bash
./sagemake --install
```

This produces the `sagevm` binary (and symlinks for `sgvm`/`sgvmc`).

## Unified CLI (sagevm)

- **`sagevm run <file.sgvm|.sgrv> [--debug] [--safe] [--no-exec] [--no-ffi] [--riscv]`**: Execute a compiled binary. Auto-detects architecture via magic headers (SGRV vs SGVM).
- **`sagevm compile <file.sage> [output.sgvm|.sgrv] [--shebang] [--riscv]`**: Compile source to binary. Use `--riscv` for register-based output. Reports final binary size on success.
- **`sagevm dis <file.sgvm|.sgrv> [--sage | --svm] [--riscv]`**: Disassemble binary into readable instructions. Auto-detects architecture.
- **`sagevm hex <file.sgvm|.sgrv> [--riscv]`**: Low-level binary hexdump. Auto-detects architecture.
- **`sagevm version`**: Show version information.

## Architectures

### 1. SVM (Stack Virtual Machine)
The traditional SGVM architecture. Uses variable-length bytecode and a 65,536-entry operand stack. Optimized for code density and simple compiler targets.

### 2. SRVM (Sage RISC-V Virtual Machine)
A modern, register-based architecture based on the **RV64I** specification.
- **32 x 64-bit registers**: Standard RISC-V register file mapping.
- **Fixed-width encoding**: 32-bit instructions for simplified decoding and high-speed dispatch.
- **Performance**: Up to 30-40% faster interpretation for arithmetic-heavy code.

## Performance Benchmarks (v0.9.9)

| Benchmark | SVM (ms) | SRVM (ms) | Improvement |
|-----------|----------|-----------|-------------|
| `fibonacci(22)` | 2256 | 1580 | 30% |
| `loop_sum` | 4513 | 3120 | 31% |
| `exception_handling` | 417 | 290 | 30% |

*Note: Benchmarks reflect interpretation overhead in a pure SageLang environment.*

## Documentation

- [Architecture](docs/ARCHITECTURE.md): Technical details of SVM and SRVM.
- [Specification](docs/SPEC.md): Formal specification of binary formats and execution.
- [RISC-V Design](docs/rv64.md): Deep dive into the SRVM register-based design.

## License

This project is licensed under the same terms as SageLang.
