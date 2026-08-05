# Bolt's Performance Journal

## 2026-08-04 - In-Place Stack Peeking for Binary Operators & Bypassing Bounds Checks on Global Writes
**Learning:** In the SVM interpreter hot loop, binary, comparison, and bitwise operators (such as `OP_ADD`, `OP_SUB`, `OP_LESS`, etc.) were popping elements off the `stack` list sequentially, modifying the list size multiple times and updating indices. By peeking at elements directly using `stack[stack_len-1]` and `stack[stack_len-2]`, executing the operation, writing the result directly into `stack[stack_len-2]`, and then calling a single `pop(stack)` at the end, we completely bypass sequential Python/SageLang-level list modification and length check overhead. Furthermore, removing redundant stack overflow checks on jumps/loops (which do not grow the stack) and placing `global_cache_dict[idx]` checks at the absolute top of `OP_SET_GLOBAL` yields an additional ~15% real-time execution speedup on the 1M-iteration loop benchmark, dropping times from ~10.8s to ~9.1s.
**Action:** Refactor sequential stack operations to use single-pass stack peeking and in-place updates, and keep jumps lean by omitting stack boundary checks.

## 2026-08-03 - Bypassing Stack Pre-Growing Loops in Local Writes & Caching Global Constants
**Learning:** In the SVM interpreter hot loop, local variable assignment (`OP_SET_LOCAL`) was repeatedly iterating to pre-grow the stack via a `while` loop, checking limits and executing stack push operations. Since locals are almost always written to pre-existing stack positions, bypassing the allocation loop using a fast-path branch (`if target_idx < stack_len`) completely eliminates this loop overhead. Furthermore, relocating the inline global lookup cache hit check to the top of `OP_GET_GLOBAL` bypasses unnecessary constant pool bounds checking and safe-mode prefix checks. Together, these optimizations yielded a massive ~15% speedup on the 1M iteration loop benchmark, dropping execution time from ~10.4s to ~8.9s.
**Action:** Implement fast-path branching to bypass safety loops (such as stack growth or bounds checks) when target indices are within bounds, and place inline cache checks at the absolute top of VM dispatch operations to bypass any redundant preprocessing.

## 2026-08-01 - Inline Truthiness Evaluation in VM Loop
**Learning:** In the SVM interpreter hot loop, calling the `is_truthy` procedure repeatedly in opcodes like `OP_JUMP_IF_FALSE`, `OP_NOT`, and `OP_TRUTHY` introduces substantial function call and stack-frame allocation overhead. By inlining the truthiness check using the direct logical evaluation `cond == nil or cond == false or cond == 0 or cond == ""` (or its boolean negation), we completely eliminate function calls in these opcodes. This reduces loop benchmark execution times by ~13.3% and slashes system/GC time by over 48%.
**Action:** Inline frequently called utility and predicate checks inside interpreter hot loops to bypass function dispatch and heap allocation costs.

## 2026-07-29 - Numerical Type Cache & Fast-Path in VM Loop
**Learning:** In the SVM interpreter, `OP_ADD` and `OP_MUL` repeatedly invoke the `type()` builtin function on operands, resulting in up to 6 heap string allocations and comparisons in C for a single operation. By pre-evaluating and caching `let type_a = type(a)` and `let type_b = type(b)` once, and testing the common numerical path `type_a == "number" and type_b == "number"` first, we bypass redundant type queries and string comparisons. This reduces benchmark execution time by ~42% (from 19.35s to 11.20s real time) and cuts system time (garbage collection/string allocations) by over 73%.
**Action:** Pre-evaluate and cache dynamic runtime type descriptors once per operation in interpreter hot-paths, and route immediately to fast-paths for the most common operand type combinations.

## 2026-07-28 - Inline Global Variable Resolution Cache
**Learning:** In the SVM interpreter, repeatedly looking up global variables by name via sequential `scopes` list searches and `globals` dictionary lookups inside hot loops (`OP_GET_GLOBAL`, `OP_SET_GLOBAL`) incurs massive SageLang execution overhead. Since constant pool indices (`idx`) are unique to each variable reference, we can implement an inline lookup cache array mapped to the constant pool index. By storing the resolved dictionary (e.g. `global_scope`, `globals`, or `scopes[si]`) in the cache on first access and directly reading/writing on subsequent hits, we bypass name resolution completely. This yields a massive ~31.4% improvement in VM execution speed, with the 1M iteration loop benchmark dropping from 15.6s to 10.7s. It is crucial to clear/reset this cache on `OP_PUSH_ENV`, `OP_POP_ENV`, and fallback `execute_op` boundaries to ensure correctness when scope contexts change.
**Action:** Implement constant-index-mapped inline caches for high-frequency dynamic name resolutions in virtual machine interpreters, ensuring cache flushes at any boundary that mutates the scoping stack.

## 2026-07-25 - Local Global Scope Caching in VM Loop
**Learning:** In the SVM interpreter (`src/svm/sgvm_vm.sage`), repeatedly accessing the global scope via `scopes[0]` introduces significant SageLang-level list indexing overhead in the hot instruction dispatch loop. By caching `scopes[0]` as a local variable `global_scope` inside `MetalVM.run` (declaring `scopes` as mutable via `var`), and synchronizing both `scopes` and `global_scope` after any non-inlined `execute_op` fallback, we bypass the list indexing penalty entirely. This yields a measurable execution speedup, reducing loop benchmark times from ~15.9s to ~15.6s, while preserving correct lexical scoping and generator state-swap correctness.
**Action:** Cache top-level indices of list structures (such as `scopes[0]`) into local variables in high-frequency interpreter loops when their reference remains stable, ensuring proper synchronization back from VM state on fallback boundaries.

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
**Learning:** Caching interpreter state (`ip`, `code`, `stack`, and `current_local_base`) as local variables in the `MetalVM.run` loop significantly reduces property access overhead, providing a ~10-15% speedup in arithmetic-heavy loops. Inlining common opcodes like `OP_NIL`, `OP_TRUE`, `OP_FALSE`, `OP_DUP`, and comparison operators further reduces the frequency of `execute_op` calls.
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
