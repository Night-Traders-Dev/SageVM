# SGVM Toolchain TODO Implementation Plan

## Summary

Working through the TODO.md items for the standalone SGVM toolchain. Research has identified root causes for most critical issues.

## Findings from Research

### Bug 1: Bytecode Serialization — Compiler emits zeroed chunks for classes
The `sgvmc` compiler's second pass (code emission, line ~237-297 of `sgvm_compiler.sage`) handles opcode operand rewriting. The class definition chunk `35 00 04 0d 00 00 36 00 05 0d 00 01 36 00 06 06 00 04 01 2c` is being emitted as `35 00 04 0d 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 2c` — everything after `LOAD_FUNCTION(0)` is zeroed. 

**Root cause**: In the compiler's second pass `elif op == 0` branch (line 250, 294), `OP_CONSTANT` is opcode 0. After processing `LOAD_FUNCTION(0x0d)` with operand `00 00`, the next byte `36` (METHOD) is read, but the code falls through to `elif op == 0` check at line 294 which is a dead branch (already handled at line 250). The real issue: the `elif` chain at line 250 checks `op == 0` but opcode 0 is already the *first* branch — line 294's `elif op == 0` is unreachable dead code that causes a `continue`, skipping bytes. Actually, the real problem is the operand-size handling doesn't account for `OP_INHERIT(55)` and `OP_END_TRY(57)` — these are 0-operand opcodes that fall through without advancing `j`, causing desync.

### Bug 2: Class Instantiation — `no __class__ on instance`
The class definition chunk fails verification (`OOB operand for OP 0 at IP 18`) because the bytecode is corrupted (Bug 1). Fixing the compiler will fix instantiation.

### Bug 3: Import Mismatch / SAGE_PATH
`build.sh` hardcodes `/root/Devel/SageVM/.deps/SageLang/core/lib` — needs to use relative paths. The `sgvmc` compiler calls `sys.exec("sage --emit-vm ...")` which needs `sage` on PATH and `SAGE_PATH` set.

### Bug 4: C Runtime Warnings
The `--compile` flag generates C code with long string constants. This is a SageLang compiler issue, not fixable here — but we can suppress with `-Wno-overlength-strings`.

### Bug 5: Missing Native Modules
The VM's `setup_builtins()` already registers `math`, `io`, `sys`, `re`, etc. The `load_module()` method handles these. This is working correctly for builtin modules.

---

## Proposed Changes

### 1. Fix Bytecode Serialization in Compiler

#### [MODIFY] [sgvm_compiler.sage](file:///home/kraken/Devel/SageVM/src/sgvm_compiler.sage)

The second-pass code emission loop (lines 245-296) has issues:
- `OP_INHERIT(55)` and `OP_END_TRY(57)` are 0-operand opcodes not handled in the elif chain → they fall through silently but `j` doesn't advance past nonexistent operands, which is actually fine for 0-operand opcodes
- The real bug: line 294 `elif op == 0` is dead code since op==0 is handled at line 250. Remove it.
- More importantly: `OP_SETUP_TRY(56)` is in the jump group (line 278) ✓, but `OP_CLASS(53)` remapping at line 268-272 only advances `j += 4` — this is correct.

Let me re-trace: the class chunk SVM code is `3500000d00003600010d0001360002060003012c`. After hex parsing:
- `35` = CLASS(53), reads 4 hex chars (2 bytes) for const index → remaps → writes 2 bytes. j += 4 ✓
- `0d` = LOAD_FUNCTION(13), reads 4 hex chars → writes 2 bytes. j += 4 ✓  
- `36` = METHOD(54), in the `op == 9 or op == 10 or op == 52 or op == 54` group → reads 4 hex chars, remaps const, writes 2 bytes. j += 4 ✓
- `0d` = LOAD_FUNCTION again ✓
- `36` = METHOD again ✓
- `06` = DEFINE_GLOBAL, handled at line 250 group ✓
- `01` = NIL, 0-operand, no elif match → falls through. But wait — does it hit line 294 `elif op == 0`? No, op is 1.
- `2c` = RETURN(44), 0-operand, no match → falls through correctly.

The logic *should* work... Let me check if there's actually a different issue. The `continue` on line 293 (`elif op >= 60 and op < 100`) shouldn't fire. Line 294 `elif op == 0` is unreachable dead code.

I need to test this more carefully with actual execution. Let me adjust the plan to be more iterative.

---

> [!IMPORTANT]
> After deeper analysis, the compiler code *looks* correct on paper for the class case. The bug may be in how the compiled `sgvmc` binary handles the hex parsing (a compiled-mode arithmetic issue similar to the one fixed in conversation b8382b83). I'll need to test iteratively.

### Plan of Attack

**Phase 1: Fix build infrastructure**
- Fix `build.sh` to use correct relative paths
- Add `-Wno-overlength-strings` to suppress C warnings  
- Rebuild `sgvm` and `sgvmc` binaries

**Phase 2: Debug and fix bytecode serialization**
- Add diagnostic prints to the compiler's second pass
- Run class test through interpreted `sgvmc` to isolate compiled-vs-interpreted difference
- Fix the root cause (likely a nested expression issue in compiled mode, per conversation b8382b83)

**Phase 3: Harden OP_TRY/OP_RAISE**
- Already implemented in `sgvm_vm.sage` (lines 872-890)
- Add proper exception object structure (type + message)
- Add `finally` support (run cleanup code regardless of exception)

**Phase 4: Create test suite**
- Create `testsuite/` with test cases covering: basic ops, classes, exceptions, math, control flow
- Create a `run_tests.sh` that compiles and runs each test, comparing output

**Phase 5: Update TODO.md**
- Mark completed items, update status

---

## Verification Plan

### Automated Tests
- Run each test in `testsuite/` through both interpreted (`sage sgvm.sage`) and compiled (`./sgvm`) paths
- Compare outputs to expected values
- `run_tests.sh` will report pass/fail for each

### Manual Verification  
- `./sgvmc testsuite/test_class.sage testsuite/test_class.sgvm && ./sgvm testsuite/test_class.sgvm`
- `./sgvm hello.sgvm` should print only "Modularized Hello!" (no debug output)
