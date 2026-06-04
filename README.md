# SGVM-Sage: SageLang Virtual Machine Tools

This repository contains the SageLang ports of the SGVM (Sage General Virtual Machine) and SGVMC (SGVM Compiler) tools. These tools allow for the compilation and execution of SageLang bytecode in a pure SageLang environment.

## Tools

### `sgvm.sage`
A pure SageLang implementation of the SGVM interpreter. It can execute compiled `.sgvm` binaries.

**Usage:**
```bash
sage sgvm.sage <file.sgvm>
```

### `sgvmc.sage`
A pure SageLang bytecode compiler/linker. It takes the intermediate VM output from the main SageLang compiler and packs it into a binary `.sgvm` artifact suitable for execution by `sgvm.sage` or the C-based MetalVM.

**Usage:**
```bash
sage sgvmc.sage <input.sage> <output.sgvm>
```

## Integration with SageLang

This repository is intended to be used as a submodule within the main SageLang repository, typically located at `core/src/sage/vm-tools`.

## Development

The opcodes used by these tools must stay in lockstep with the primary specification in the SageLang repository (`core/src/vm/bytecode.h`).

## License

This project is licensed under the same terms as SageLang (see LICENSE in the main repository).
