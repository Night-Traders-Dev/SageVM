# Test string utilities (chr, ord, startswith, endswith)
# BUG: These builtins are documented in docs/SPEC.md but are NOT currently
# implemented in src/svm/sgvm_vm.sage's setup_builtins or call_builtin handlers.
# Expect: "Error: Callee not a function or builtin name"
print "chr(65): " + chr(65)
print "ord('A'): " + str(ord("A"))
print "startswith('hello', 'he'): " + str(startswith("hello", "he"))
print "startswith('hello', 'world'): " + str(startswith("hello", "world"))
print "endswith('hello', 'lo'): " + str(endswith("hello", "lo"))
print "endswith('hello', 'world'): " + str(endswith("hello", "world"))
