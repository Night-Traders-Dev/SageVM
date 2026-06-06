# TODO: Standalone SGVM Toolchain

## Critical Issues (Runtime/Build)
- [ ] **Bytecode Serialization Bug**: Investigate and fix OOB operand errors during `OP_CALL` bytecode verification in `sgvm`.
- [ ] **Class Instantiation**: Resolve `no __class__ on instance` runtime errors for native class definitions.
- [ ] **Python/SageLang Import Mismatch**: Finalize the `sgvmc` import logic to reliably find `sgvm_core` without requiring `PYTHONPATH` hacks.
- [ ] **C Runtime Warnings**: Resolve overlong string constant warnings (`string length is greater than the length 4095`) in generated C code.
- [ ] **Missing Native Modules**: Ensure `lib/` modules (e.g., `net`, `math`) are correctly available to the compiled VM artifacts.

## Implementation Tasks
- [ ] **Hardened VM**: Complete the native implementation of `OP_TRY`/`OP_RAISE` in `src/sgvm_vm.sage`.
- [ ] **Direct SGVM Backend**: Integrate a binary `.sgvm` emitter directly into the main SageLang compiler.
- [ ] **Portable Distribution**: Create a `dist/` package containing the native `sgvm` binary and bytecode-compiled standard library.

## Verification
- [ ] Run full test suite (`testsuite/`) using the standalone `sgvm` binary.
- [ ] Benchmark performance improvements from AOT vs interpreted bytecode.
