# SageVM Testing

## Build
To build the SageVM tools (`sgvm` interpreter and `sgvmc` compiler):
```bash
make
```
This requires `python3` and the `rich` library (`pip install rich`).

## Running Tests
To run the automated test suite:
```bash
make test
```
The `test` target in the `Makefile` handles several environment-specific setup tasks:
- Mocks `curl/curl.h` if missing in the SageLang submodule to allow compilation in restricted environments.
- Bootstraps the `sage` host binary with custom `LDFLAGS` if it hasn't been built.
- Ensures `sgvm` and `sgvmc` symlinks are present.
- Executes `python3 tests/run_tests.py` to run the modern coverage suite.

The test suite performs the following for each `.sage` file in the `tests/` directory:
1. Compiles the `.sage` file to `.sgvm` bytecode using `./sgvmc`.
2. Runs the compiled bytecode using `./sgvm`.
3. Filters out `DEBUG:` logs and compares the output against the corresponding `.expected` file.

Note: The `testing/` directory contains historical tests, while `tests/` is used for modern coverage verification. New tests added for exceptions, OOP, dictionaries, arithmetic/comparisons, type conversions, bitwise XOR/NOT, explicit truthiness, sys.args, indexing assignments, GC/reflection, memory management, binary structures, all types coverage, slicing syntax, functions with many arguments, nested collections, higher-order functions, instance properties, modulo edge cases, nested scopes, large constant pools, string concatenation, float arithmetic, GPU time, string repetition, short-circuiting, division by zero, unary operators, return values, global persistence, anonymous/higher-order functions, variable shadowing, and collection equality are located here.

### Build Environment & Headless Setup
- Automated `make test` executes builds using `SAGE_NO_GUI=1` and `-DSAGE_NO_GUI` flags to ensure headless build compatibility without `libglfw.so.3` graphics library dependencies.

### Coverage Expansion (September 2026 - Forge Daily)
- `array_concat_edge.sage`: Tests array concatenation (`OP_ADD`), empty arrays, nested arrays, array-string coercion, and fallback behavior for non-array additions.
- `comparison_ops_edge.sage`: Tests relational (`<`, `<=`, `>`, `>=`) and equality (`==`, `!=`) opcodes across numbers, strings, booleans, nil, and collections (noting SVM behavior where non-numeric relational comparisons evaluate to false).
- `float_ops_edge.sage`: Tests floating-point arithmetic (`OP_ADD`, `OP_SUB`, `OP_MUL`, `OP_DIV`, `OP_MOD`), float comparisons (`OP_GREATER`, `OP_LESS_EQUAL`, `OP_EQUAL`), float type conversions (`int()`, `tonumber()`), and float division by zero (`1.0 / 0.0`).
- `dict_ops_edge.sage`: Tests dictionary property access (`OP_GET_PROPERTY`, `OP_SET_PROPERTY`), element indexing (`OP_GET_INDEX`, `OP_SET_INDEX`), missing string keys/properties evaluating to `nil`, and nested dictionary reassignments.
- `function_args_edge.sage`: Tests function calls (`OP_CALL`, `OP_RETURN`) with parameter binding, excess arguments, missing arguments, and conditional early returns.
- `math_module_edge.sage`: Tests `math` module functions (`math.abs`, `math.sqrt`, `math.sin`, `math.cos`, `math.printm`), constants (`math.pi`, `math.e`), non-array `math.printm` error handling, and invalid/negative/nil parameter inputs.
- `local_vars_edge.sage`: Tests local variable read/write operations (`OP_GET_LOCAL`, `OP_SET_LOCAL`), parameter bindings (`arg0`, `arg1`, `arg2`), loop variable reassignments, shadowing globals, and accessing uninitialized local slots.
- `nested_loops_edge.sage`: Tests nested `while` loops, function-scoped loop execution, global loop counters, and zero-iteration inner loops.
- `loop_try_catch_edge.sage`: Tests `try-catch` exception handling inside loop bodies (`OP_SETUP_TRY`, `OP_END_TRY`, `OP_RAISE`), exceptions in sequential loops, and exceptions thrown and caught within nested loops.
- `recursion_edge.sage`: Tests recursive function calls (`OP_CALL`, `OP_RETURN`), parameter binding across stack frames, mutual recursion (`is_even` / `is_odd`), accumulator recursion, and base conditions.
- `global_redefine_edge.sage`: Tests global variable declarations (`OP_DEFINE_GLOBAL`), reassignments (`OP_SET_GLOBAL`), scope cache invalidation, global updates inside functions and loops, conditional reassignments, and global collection mutations.
- `bitwise_expr_edge.sage`: Tests chained bitwise expressions (`OP_BIT_AND`, `OP_BIT_OR`, `OP_BIT_XOR`, `OP_SHIFT_LEFT`, `OP_SHIFT_RIGHT`), bitwise NOT (`~`) on zero and negative boundary values, and nil operand bitwise operations.
- `logical_expr_edge.sage`: Tests logical expression chaining (`and`, `or`, `not`), non-boolean truthiness evaluation across primitive and collection types in conditionals, and short-circuit evaluation side-effect skipping.
- `array_mutation_edge.sage`: Tests array element indexing (`OP_GET_INDEX`, `OP_SET_INDEX`), in-place array index mutations, nested matrix mutations, `push` and `pop` operations, and edge conditions (pop on empty array, out-of-bounds indexing).
### Coverage Expansion (October 2026 - Forge Daily)
- `class_method_dispatch_edge.sage`: Tests OOP class constructors (`init(self, ...)`), method chaining returning `self`, `self` calling internal methods, multi-parameter method dispatch, dynamic property creation, and accessing/calling non-existent properties/methods on instances.
- `chained_assignment_edge.sage`: Tests stack manipulation opcodes (`OP_DUP`, `OP_POP`) across chained variable assignments (`var a = var b = var c = 100`), arithmetic expression assignments, chained `nil` assignments, chained array index assignments, chained dictionary key assignments, and chained object property assignments.
- `unary_negate_edge.sage`: Tests `OP_NEGATE` (unary `-x` operator) across positive and negative integers, floating point numbers, zero, arithmetic expressions, chained negations (`--x`, `---x`), `nil` (evaluates to `0` in SVM), booleans, strings, and array operands.
- `string_repeat_edge.sage`: Tests string repetition (`OP_MUL` string * int and int * string) with positive counts, zero, negative multipliers, float multipliers, empty strings, chained expressions, and `nil` operands.
- `dict_key_types_edge.sage`: Tests dictionary indexing (`OP_GET_INDEX`, `OP_SET_INDEX`) with non-string keys (integers, floats, booleans, nil), string conversion via `str()`, dictionary reflection builtins (`dict_has`, `dict_keys`, `dict_values`), and missing key evaluation behavior.
- `nested_block_return_edge.sage`: Tests early function returns (`OP_RETURN`) from deep nested block scopes (`OP_PUSH_ENV`), nested conditionals, nested loops, and `try-catch` blocks inside functions while verifying environment scope stack balance.
- `string_escapes_edge.sage`: Tests string escape sequences (`\n`, `\t`, `\\`, `\"`), string indexing and length on multi-line strings, character conversions (`ord`, `chr`), splitting/joining on newline delimiters, and `strip` functionality.
- `string_replace_edge.sage`: Tests `replace()` string builtin across deletion, empty target strings, multiple pattern occurrences, escape characters (`\n`), whole string replacements, and nil arguments.
- `dict_nested_mutation_edge.sage`: Tests nested dictionary creation, deep property/index mutation (`d["a"]["b"]` and `d.a.b`), keys with spaces and symbols (`special["first name"]`), missing nested key access, and dictionary mutations in loops.
- `array_pop_push_boundary_edge.sage`: Tests array stack operations (`push()` and `pop()`), popping on empty arrays returning `nil`, pushing heterogeneous types (arrays, strings, nil, ints), and interleaved push/pop in loops with `len()` tracking.
- `func_scope_chain_edge.sage`: Tests nested function definitions, non-lexical closure scope resolution (unbound outer local variables resolving to `nil`), global scope fallback, explicit parameter passing to inner functions, and parameter shadowing global variables.
- `exception_unwind_call_edge.sage`: Tests exception unwinding across multi-level nested function call frames, re-raising exceptions across try-catch blocks, and return statements executed inside try blocks.
- `split_join_types_edge.sage`: Tests `split()` and `join()` builtins with multi-character delimiters, empty string delimiters, mixed-type arrays, empty arrays, single-element arrays, empty delimiters, and nil parameters.
- `slice_boundary_edge.sage`: Tests `slice()` builtin and slice operator with boundary clamping values, exact full copies, zero-length slices, and empty collections.
- `modulo_edge.sage`: Tests `OP_MOD` (`%`) across positive/negative integers, floating-point modulo, division/modulo by zero (`10 % 0`), and nil/invalid operands.
- `bitwise_not_edge.sage`: Tests `OP_BIT_NOT` (`~`) on positive/negative integers, zero, bitwise NOT expressions, double bitwise negation, and `nil` operand handling.
- `logical_not_edge.sage`: Tests `OP_NOT` (`not`) across boolean values, `nil`, integers, floats, empty/non-empty strings, collections (arrays and dicts), logical expressions, and chained negation (`not not`).
- `short_circuit_merge.sage`: Activates test for short-circuit result value evaluation, boolean and truthiness preservation across logical expression continuations, and nested expression evaluation.
- `for_loop_collections_edge.sage`: Tests `for` loops across collection types including nested arrays, strings, empty arrays, empty strings, and nil boundary conditions.
- `string_search_index_edge.sage`: Tests string character indexing, length (`len`), containment (`contains`), prefixes/suffixes (`startswith`/`endswith`), slicing (`slice`), case transformations (`upper`/`lower`), whitespace stripping (`strip`), string replacement (`replace`), and ASCII conversions (`ord`/`chr`).
- `func_dispatch_collection_edge.sage`: Tests function references stored in arrays and dictionaries, dynamic function dispatch via index/key lookup, function reassignment in collections, higher-order collection pipeline dispatch, and missing function handle lookups.
- `array_slice_mutation_edge.sage`: Tests array slice operator `[s:e]` and `slice()` builtin on 1D/2D arrays, copy independence on element mutation, 0-length slices, start > end ranges, and empty array slicing.
- `for_loop_dict_iteration_edge.sage`: Tests dictionary key/value iteration in loops, value mutations, empty dictionaries, and non-string key indexing behavior.
- `matrix_multi_dim_mutation_edge.sage`: Tests 2D/3D matrix creation, nested index element mutation (`m[i][j]`), row/column sum traversals, and out-of-bounds index handling.

### Verification Status (October 2026)
The modern SVM coverage suite passes except for the three pre-existing front-end/scoping failures noted below.

One test is skipped: `generators.sage`, because `sage --emit-vm` does not
emit VM bytecode for it.

Note when adding tests: the harness compiles each test with the SageLang in
`.deps/SageLang`, which is an unmanaged clone rather than a pinned submodule.
If that clone is stale, a test can fail for reasons that have nothing to do
with the VM. Check what it is pinned at before debugging a failure.

Security tests are named `security_*.sage`; the harness passes `--safe` to
those automatically.

The full SRVM suite is not green in the current checkout: the register backend still has broad compatibility gaps. See docs/CHANGELOG.md.

## Adding Tests
Add a `.sage` file to the `tests/` directory and a corresponding `.expected` file containing the expected stdout output.
