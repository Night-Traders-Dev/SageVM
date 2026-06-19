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

Note: The `testing/` directory contains historical tests, while `tests/` is used for modern coverage verification. New tests added for exceptions, OOP, dictionaries, arithmetic/comparisons, and type conversions are located here.

### Known Intentional Failures
The following tests are expected to fail in the current implementation:
- `tests/oop.sage`: Fails due to an opcode collision at index 59 (the VM interprets `GET_LOCAL` as `GPU_POLL_EVENTS`).
- `tests/locals_test.sage`: Fails because `OP_GET_LOCAL` (88) and `OP_SET_LOCAL` (89) are currently unimplemented stubs in the SVM interpreter.
- `tests/break_continue.sage`: Fails because `OP_BREAK` and `OP_CONTINUE` are currently unimplemented stubs that halt execution.

## Adding Tests
Add a `.sage` file to the `tests/` directory and a corresponding `.expected` file containing the expected stdout output.
