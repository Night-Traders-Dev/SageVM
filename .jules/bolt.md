# Bolt's Performance Journal

## 2026-06-25 - Interpreter Hot-Loop Optimization
**Learning:** Accessing local variables in the SVM interpreter via call stack dictionary lookups is a significant bottleneck. Caching the `current_local_base` in the `MetalVM` object provides a ~15% speedup in arithmetic loops. Inlining BE16 decoding also reduces overhead.
**Action:** Always look for cached state opportunities in interpreter hot loops. Avoid unnecessary dictionary lookups in opcodes like `OP_GET_LOCAL` and `OP_SET_LOCAL`.

## 2026-06-26 - Dispatch Loop Optimization & JIT Overhead
**Learning:** The SRVM interpreter was performing string concatenations and dictionary lookups on every single instruction for an unimplemented JIT's hot-path detection. Removing this provided a ~60% speedup. In the SVM backend, inlining `run_step` and caching the stack pointer in a local variable reduced dispatch overhead by ~20%.
**Action:** Avoid expensive string/dict operations in instruction fetch/decode. Inline tight dispatch steps to minimize function call overhead.

## 2026-07-01 - Arithmetic and Global Access Inlining
**Learning:** Inlining the logic for arithmetic (MUL/DIV), comparison (EQUAL/NOT_EQUAL), and global variable access (GET_GLOBAL/SET_GLOBAL) directly into the `MetalVM.run` loop achieved a ~3x speedup (~14.6s to ~4.8s) in arithmetic-heavy benchmarks by eliminating the overhead of repeated `execute_op` function calls.
**Action:** Prioritize inlining the most frequent opcodes (found via profiling or common patterns like loop counters) into the main interpreter loop.
