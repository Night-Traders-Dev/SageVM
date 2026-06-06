# SGVM TODO Task Tracker

## Phase 1: Fix Build Infrastructure
- [x] Fix `build.sh` hardcoded paths
- [x] Add C warning suppression
- [x] Rebuild binaries

## Phase 2: Debug & Fix Bytecode Serialization
- [/] Test `sgvmc` in interpreted mode vs compiled mode
- [ ] Identify root cause of zeroed class chunks
- [ ] Fix compiler second-pass code emission
- [ ] Verify class test passes

## Phase 3: Harden OP_TRY/OP_RAISE
- [ ] Add structured exception objects
- [ ] Add finally support
- [ ] Test exception handling

## Phase 4: Create Test Suite
- [ ] Create test files (basic, arithmetic, classes, exceptions, control flow)
- [ ] Create `run_tests.sh` automation script
- [ ] Run full test suite

## Phase 5: Update Documentation
- [ ] Update TODO.md with completed items
- [ ] Update CHANGELOG.md
