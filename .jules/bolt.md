# Bolt's Performance Journal

## 2026-07-26 - Global Scope Caching and Fallback Optimization
**Learning:** Accessing list indices repeatedly (e.g., `scopes[0]`) in interpreter hot loops incurs high compiler-level and runtime list bounds-checking overhead. By caching the outermost global scope (`scopes[0]`) in a local variable `global_scope` inside `MetalVM.run` and synchronizing it after non-inlined `execute_op` boundaries, we completely eliminated list indexing overhead for fast-paths and fallback scope loops, resulting in a ~56% speedup (from 35.1s to 15.2s real-time) on tight global variable loops.
**Action:** Cache static outer list/dictionary indices as local variables inside critical interpreter dispatch loops and use robust fallback synchronization to maintain correctness across execution boundaries.

## 2026-07-24 - Global Scope dict_has Bypass and Fast-Path Routing
**Learning:** In the SVM interpreter, calling `dict_has` repeatedly on scope/globals lookups and assignments inside hot loops causes significant function call and key-existence check overhead. In SageLang, querying a missing key natively evaluates to `nil` instead of panicking. Leveraging this by directly querying `scopes[si][name]` and `globals[name]`—and using `dict_has` only as a fallback when a key is explicitly mapped to `nil`—bypasses the existence check 99.9% of the time, resulting in a ~14.2% overall performance speedup on variable assignment and lookup heavy loops.
**Action:** Always bypass existence checks (like `dict_has` or `in` lookups) by directly indexing or retrieving values and checking against `nil`/`None` when the host language supports safe missing-key evaluation.

## 2026-07-17 - Stack Size Local Caching and Maintenance
**Learning:** Calling `len(stack)` repeatedly in hot-loops inside the SVM interpreter is highly expensive, especially when list indexing/peeking and conditional operations rely on it. Caching and manually maintaining the stack size in a local variable (`stack_len`) inside the `MetalVM.run` hot-loop yields a substantial ~39% speedup (~18.2s to ~11.0s) on loop-heavy benchmarks.
**Action:** Track collection sizes locally when they change predictably via push/pop inside interpreter hot-loops, and synchronize back only on non-inlined or fallback boundaries.

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

## 2026-07-13 - Stack Peeking and Dispatch Inlining
**Learning:** In the SVM interpreter, replacing pop/push cycles with stack peeking (`stack[len(stack)-1]`) for assignments and property/index lookups reduces the overhead of Python-level list modifications and length checks, yielding a measurable speedup. Inlining property access into the main dispatch loop further reduces function call overhead.
**Action:** Prioritize stack peeking over pop/push for all opcodes that update or access the top of the stack.

## 2026-07-16 - Hot-Loop Stack Overflow Check Optimization
**Learning:** Checking stack overflow limits (`len(stack) > max_stack`) on every single bytecode instruction inside an interpreter hot loop incurs a heavy performance penalty due to frequent list length and comparison operations. Since infinite stack growth is theoretically impossible without control-flow/loops (`OP_JUMP`, `OP_LOOP_BACK`), function/method recursion (`OP_CALL`, `OP_CALL_METHOD`), or exception handling blocks (`OP_SETUP_TRY`), restricting the overflow check to only these key opcodes preserves complete safety boundaries while eliminating the check from standard linear instructions. Removing it from conditional forward jumps (`OP_JUMP_IF_FALSE`) further optimizes loop headers, resulting in a ~41% overall execution speedup.
**Action:** Relocate resource exhaustion and safety boundary checks from the main instruction dispatch loop to control flow, function calls, and loop-back boundaries.

## 2026-07-20 - Lexical Scope Lookup and Dict Key Bypassing
**Learning:** Calling `dict_has` repeatedly to verify key existence before subscript dictionary lookups in the interpreter hot-loop (e.g., `OP_GET_GLOBAL`) incurs massive performance overhead due to repeated C-level function call dispatches and validation logic. In SageLang, looking up a missing key from a dictionary is natively safe and evaluates to `nil` rather than raising a KeyError/runtime panic. Bypassing `dict_has` for successful innermost scope hits and falling back to safety checks only on `nil` results reduces loop execution time by ~38% (~17.8s to ~11.0s) on global-scope variable loops.
**Action:** Always bypass `dict_has` checks by directly querying the dictionary and verifying if the result is non-nil, falling back to safe checks or outer scoping rules only when the returned value is `nil`.
