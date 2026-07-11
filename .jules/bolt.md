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

## 2026-07-04 - Interpreter State Caching and Opcode Inlining
**Learning:** Caching interpreter state (`ip`, `code`, `current_local_base`, `scopes`, `globals`) as local variables in the `MetalVM.run` loop significantly reduces property access overhead, providing a ~10-15% speedup in arithmetic-heavy loops. Inlining common opcodes like `OP_NIL`, `OP_TRUE`, `OP_FALSE`, `OP_DUP`, and comparison operators further reduces the frequency of `execute_op` calls.
**Action:** When optimizing an interpreter, always prioritize caching the instruction pointer and current code chunk. Ensuring that most loop-related opcodes are inlined prevents costly function call overhead during dispatch.

## 2026-07-04 - Local Variable Caching and State Synchronization
**Learning:** Caching `self` properties (like `ip`, `code`, `stack`, and `current_local_base`) as local variables in the `MetalVM.run` loop provided an ~11% speedup. However, it is critical to synchronize these locals back from `self` after calling any non-inlined method (like `execute_op`) because operations like function calls or returns can swap the active code chunk (`self.code`) and reset the instruction pointer.
**Action:** Use local variable caching for VM hot loops, but always implement "sync-on-fallback" logic when dispatching to external handlers.

## 2026-07-08 - Loop Invariant Caching and Dispatch Reordering
**Learning:** Caching `len(code_bytes)` and `len(constants)` in the `MetalVM.run` loop avoids repeated calls to the `len()` builtin, which has measurable overhead in tight loops. Reordering the opcode dispatch chain to put the most frequent instructions (GET_LOCAL, CONSTANT, ADD, SET_LOCAL, LOOP_BACK, JUMP_IF_FALSE, LESS, POP) at the top of the `if/elif` block further reduces comparison overhead for hot-path instructions.
**Action:** Always cache collection lengths and reorder dispatch chains based on instruction frequency in performance-critical interpreters.

## 2026-07-12 - Global Access Fast-Path for Single Scope
**Learning:** The SVM interpreter's global variable access (GET_GLOBAL/SET_GLOBAL) had high overhead due to a while loop traversing scopes, even when only a single local scope was present (common in flat scripts or global loops). Peeking at the stack instead of popping/pushing for SET_GLOBAL also saves cycles.
**Action:** Implement fast-paths for common collection sizes (like len(scopes) == 1) in hot-path opcodes to skip loop overhead and redundant search logic.
