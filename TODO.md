# TODO: Standalone SGVM Toolchain (Revised)

## Phase 1: Opcode Parity (Core Stability)
- [ ] Implement missing control flow opcodes: `OP_BREAK`, `OP_CONTINUE`, `OP_PUSH_ENV`, `OP_POP_ENV`.
- [ ] Implement robust stack frame management for `OP_CALL` and `OP_RETURN` (argument passing, local variables).

## Phase 2: Native Bridge Implementation
- [ ] Define native function registry mapping function names to C pointers in `MetalVM`.
- [ ] Implement opcode for invoking registered native C functions (`MetalValue` marshaling).

## Phase 3: Object Compatibility (Minimal Runtime)
- [ ] Implement static dictionary/object representation for `MetalVM` (non-GC managed).
- [ ] Bridge static objects to minimal allocation needs for `sgvm` runtime functionality.

## Phase 4: Verification and Incremental Integration
- [ ] Implement unit tests for core opcodes and native bridge.
- [ ] Incrementally integrate `SageLang` standard library components.

## Verification (Post-Stabilization)
- [ ] Run full test suite (`testsuite/`) using the standalone `sgvm` binary.
- [ ] Benchmark performance improvements from AOT vs interpreted bytecode.
