# SGVM-Sage: SageLang Virtual Machine Tools

This repository contains the SageLang ports of the SGVM (Sage General Virtual Machine) and SGVMC (SGVM Compiler) tools. These tools allow for the compilation and execution of SageLang bytecode in a pure SageLang environment.

## Installation

To build and install the tools to your system:

```bash
make
sudo make install
```

This will compile `sgvm.sage` and `sgvmc.sage` into native binaries and install them to `/usr/local/bin`.

## Tools

### `sgvm` (Interpreter)
A pure SageLang implementation of the SGVM interpreter. It can execute compiled `.sgvm` binaries.

**Usage:**
```bash
sgvm <file.sgvm>
```

### `sgvmc` (Compiler)
A pure SageLang bytecode compiler/linker. It takes the intermediate VM output from the main SageLang compiler and packs it into a binary `.sgvm` artifact.

**Usage:**
```bash
sgvmc <input.sage> <output.sgvm> [--shebang]
```

**Options:**
- `--shebang`: Prepend a shebang line (`#!/usr/bin/env sgvm`) to the output file, allowing it to be executed directly if the execute bit is set.

## Executing .sgvm Files

If a `.sgvm` file was compiled with the `--shebang` flag, you can run it directly from the console:

```bash
sgvmc hello.sage hello.sgvm --shebang
chmod +x hello.sgvm
./hello.sgvm
```

## Integration with SageLang

This repository is intended to be used as a submodule within the main SageLang repository, typically located at `core/src/sage/vm-tools`.

## Development

The opcodes used by these tools must stay in lockstep with the primary specification in the SageLang repository (`core/src/vm/bytecode.h`).

## License

This project is licensed under the same terms as SageLang (see LICENSE in the main repository).
