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

Note: The `testing/` directory contains historical tests, while `tests/` is used for modern coverage verification. New tests added for exceptions, OOP, dictionaries, arithmetic/comparisons, type conversions, bitwise XOR/NOT, explicit truthiness, sys.args, indexing assignments, GC/reflection, memory management, binary structures, all types coverage, slicing syntax, and functions with many arguments are located here.

### Known Issues
As of June 2026, several tests are expected to fail due to documented but unimplemented features in the SVM backend:
- `array_methods.sage`: Missing `push` and `pop` builtins.
- `strings.sage`: Missing `chr`, `ord`, `startswith`, and `endswith` builtins.
- `array_ops.sage`: String slicing returns `nil` due to float-to-int conversion issues in the VM.
- `dict_builtins.sage`: Missing `dict_has`, `dict_keys`, and `dict_values` builtins.
- `string_methods.sage`: Missing `upper`, `lower`, `strip`, `replace`, `split`, and `join` builtins.
- `contains_builtin.sage`: Missing `contains` builtin.
- `truthiness_expanded.sage` and `truthy_explicit.sage`: Incorrectly treats empty strings as falsy (inherited from host SageLang behavior).
- `math_trig.sage`: `math.sin` and `math.cos` return nil.
- `mem_builtin.sage`: `mem.read` returns nil.
- `struct_builtin.sage`: `struct.def` returns nil.
- `all_types.sage`: Returns "dict" for modules, functions, classes, and instances instead of specific type names.

## Adding Tests
Add a `.sage` file to the `tests/` directory and a corresponding `.expected` file containing the expected stdout output.
