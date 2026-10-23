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

### Coverage Expansion (October 2026 - Forge Daily)
- `short_circuit_merge.sage`: Tests short-circuit logical evaluation result values, truthiness, nested logical joins, and control flow conditions.
- `for_loop_dict_iteration_edge.sage`: Tests dictionary key/value iteration in loops, value mutations, empty dictionaries, and non-string key indexing behavior.
- `matrix_multi_dim_mutation_edge.sage`: Tests 2D/3D matrix creation, nested index element mutation (`m[i][j]`), row/column sum traversals, and out-of-bounds index handling.

### Verification Status (October 2026)
The modern SVM coverage suite passes cleanly: **179 passed, 0 failed, 1 skipped** (with `generators.sage` skipped as `sage --emit-vm` does not emit VM bytecode for yield statements).

Note when adding tests: the harness compiles each test with the SageLang in
`.deps/SageLang`, which is an unmanaged clone rather than a pinned submodule.
If that clone is stale, a test can fail for reasons that have nothing to do
with the VM. Check what it is pinned at before debugging a failure.

Security tests are named `security_*.sage`; the harness passes `--safe` to
those automatically.

The full SRVM suite is not green in the current checkout: the register backend still has broad compatibility gaps. See docs/CHANGELOG.md.

## Adding Tests
Add a `.sage` file to the `tests/` directory and a corresponding `.expected` file containing the expected stdout output.
