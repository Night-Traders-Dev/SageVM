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

### Coverage Expansion (2026-07-10)
- `anon_func.sage`: Tests higher-order functions and variable-bound functions.
- `shadowing.sage`: Tests variable shadowing (local vs global).
- `collection_eq.sage`: Tests deep equality for arrays and dictionaries (bug flagged: dictionary equality fails).

### Coverage Expansion (2026-07-16)
- `generators.sage`: Tests generator creation, `yield` statement execution, and the `next()` builtin. Since the SVM interpreter doesn't support native generator opcodes, this is a documented gap.
- `security_builtin_protection.sage`: Tests host bridge security isolation by attempting to mutate protected `__builtin__`-tagged structures under `safe_mode`.

### Coverage Expansion (2026-07-15)
- `dict_property.sage`: Tests property-style access and assignment on dictionaries.
- `index_oob.sage`: Tests out-of-bounds indexing for arrays and missing keys for dictionaries.
- `call_error.sage`: Tests calling non-callable objects (bug flagged: doesn't currently raise exception).

### Coverage Expansion (2026-07-08)
- `halt_op.sage`: Verifies VM termination (bug flagged: `sys.exit` currently doesn't halt guest).
- `security_indexing.sage`: Verifies `safe_mode` index protections for `__` internal keys.
- `security_restricted.sage`: Verifies native module access blocks in `safe_mode`.

### Known Issues
As of July 2026, several tests are expected to fail due to documented but unimplemented features in the SVM backend:
- `array_methods.sage`: Missing `push` and `pop` builtins.
- `strings.sage`: Missing `chr`, `ord`, `startswith`, and `endswith` builtins.
- `array_ops.sage`: String slicing returns `nil` due to float-to-int conversion issues in the VM.
- `dict_builtins.sage`: Missing `dict_has`, `dict_keys`, and `dict_values` builtins.
- `string_methods.sage`: Missing `upper`, `lower`, `strip`, `replace`, `split`, and `join` builtins.
- `contains_builtin.sage`: Missing `contains` builtin.
- `truthiness_expanded.sage` and `truthy_explicit.sage`: Incorrectly treats empty strings as falsy (inherited from host SageLang behavior).
- `math_trig.sage`: `math.sin` and `math.cos` return nil.
- `string_repeat.sage`: String repetition with `*` is not implemented in the SVM backend.
- `mem_builtin.sage`: `mem.read` returns nil.
- `struct_builtin.sage`: `struct.def` returns nil.
- `all_types.sage`: Returns "dict" for modules, functions, classes, and instances instead of specific type names.
- `collection_eq.sage`: Dictionary equality comparison always returns false in SVM.
- `nested_scopes.sage`: Nested functions cannot access parent local variables (lack of closures); they only see global scope or own locals.
- `string_repeat.sage`: Missing SVM implementation for string repetition with `*`.
- `halt_op.sage`: Fails because `sys.exit` currently does not halt the VM interpreter.
- `generators.sage`: Fails because SVM lacks a native generator engine (`OP_YIELD`/`OP_GENERATOR_NEXT` state preservation).

## Adding Tests
Add a `.sage` file to the `tests/` directory and a corresponding `.expected` file containing the expected stdout output.
