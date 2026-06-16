# SGVM-Sage: SageLang Virtual Machine Tools

This repository contains the SageLang ports of the SGVM (Sage General Virtual Machine) and SGVMC (SGVM Compiler) tools. These tools allow for the compilation and execution of SageLang bytecode in a pure SageLang environment.

## Installation

SageVM requires SageLang **v3.7.7** or higher for full feature parity. The project uses a unified build system that produces a single native binary.

To build and install:

```bash
./sagemake --install
```

This produces the `sagevm` binary (and symlinks for `sgvm`/`sgvmc`).

## Unified CLI (sagevm)

The primary entry point is the `sagevm` tool, which supports several sub-commands:

- **`sagevm run <file.sgvm>`**: Execute a compiled binary.
- **`sagevm compile <file.sage>`**: Compile source to binary.
- **`sagevm dis <file.sgvm>`**: Disassemble binary into readable source.
- **`sagevm hex <file.sgvm>`**: Low-level binary hexdump.
- **`sagevm version`**: Show version information.

### Backward Compatibility
Legacy tools are supported via symlinks to the unified binary:
- `sgvm ...` -> `sagevm run ...`
- `sgvmc ...` -> `sagevm compile ...`

## Features (v0.9.7)

- **Delegation Bridge**: Full guest-to-host delegation for GPU, I/O, and native modules.
- **100% Opcode Parity**: Supports all 89 opcodes from SageLang `MetalVM` (0-87, 255).
- **OOP Engine**: Native support for classes, inheritance, and method dispatch.
- **Exceptions**: VM-level support for `try/catch/finally` blocks with correct stack and scope unwinding.
- **Unified Build System**: Modern orchestrator using `sagemake` with `rich` UI.
- **Standalone Mode**: Can compile `.sage` source directly to `.sgvm` binaries.
- **Matrix Visualization**: Native `math.printm` support for formatted matrix output.

## Tools

### `sgvm` (Interpreter)
A pure SageLang implementation of the SGVM interpreter. It can execute compiled `.sgvm` binaries.

**Usage:**
```bash
sgvm <file.sgvm> [options]
```

**Options:**
- `--debug`: Enable diagnostic output, including constant pool entries, data offsets, and a full bytecode trace during execution.
- `-h, --help`: Show help message.
- `-v, --version`: Show version information.

### `sgvmc` (Compiler)
A pure SageLang bytecode compiler/linker. It takes the intermediate VM output from the main SageLang compiler and packs it into a binary `.sgvm` artifact.

**Usage:**
```bash
sgvmc <input.sage|.svm> <output.sgvm> [options]
```

**Options:**
- `--shebang`: Prepend a shebang line (`#!/usr/bin/env sgvm`) to the output file, allowing it to be executed directly if the execute bit is set.
- `-h, --help`: Show help message.
- `-v, --version`: Show version information.

### `sgvm_hexdump.sage` (Disassembler)
A pure SageLang utility to disassemble `.sgvm` binaries into human-readable bytecode instructions, constant pools, and header metadata.

**Usage:**
```bash
sage tools/sgvm_hexdump.sage <file.sgvm>
```

### `diff_bytecode.sage` (Diagnostic Diff Tool)
A pure SageLang diagnostic utility to compare VM execution traces (DIAG output) or perform side-by-side hex diffs of `.sgvm` binary files.

**Usage:**
```bash
sage tools/diff_bytecode.sage <file_a> <file_b> [--hex]
```

## Executing .sgvm Files

If a `.sgvm` file was compiled with the `--shebang` flag, you can run it directly from the console:

```bash
sgvmc hello.sage hello.sgvm --shebang
chmod +x hello.sgvm
./hello.sgvm
```

## Documentation

- [Architecture](docs/ARCHITECTURE.md): Technical details of the VM implementation and opcodes.
- [Specification](docs/SPEC.md): Formal specification of the SGVM execution pipeline and verification.
- [Changelog](docs/CHANGELOG.md): History of changes and improvements.
- [Roadmap](docs/ROADMAP.md): Features and library modules yet to be implemented.

## Performance Benchmarks (v0.9.7)

SageVM tracks performance across a suite of micro-benchmarks. Below are the results for the unified `sagevm` binary (v0.9.7) running in a pure SageLang environment.

| Benchmark | Runtime | Duration (ms) |
|-----------|---------|---------------|
| `01_fibonacci.sage` (fib(22)) | sagevm | 2256 |
| `02_loop_sum.sage` | sagevm | 4513 |
| `03_string_concat.sage` | sagevm | 495 |
| `04_array_ops.sage` | sagevm | 2644 |
| `05_dict_ops.sage` | sagevm | 2542 |
| `06_class_method.sage` | sagevm | 7876 |
| `07_nested_loops.sage` | sagevm | 16991 |
| `08_exception_handling.sage` | sagevm | 417 |
| `10_primes_sieve.sage` | sagevm | 1131 |
| `runtime_compare.sage` | sagevm | 845 |

*Note: Benchmarks were run on a standardized environment. "sagevm" results reflect the pure-interpreter overhead.*

## Integration with SageLang

This repository is intended to be used as a submodule within the main SageLang repository, typically located at `core/src/sage/vm-tools`.

## Development

The opcodes used by these tools stay in 100% lockstep with the primary specification in the SageLang repository (`core/src/vm/bytecode.h`).

## License

This project is licensed under the same terms as SageLang (see LICENSE in the main repository).
