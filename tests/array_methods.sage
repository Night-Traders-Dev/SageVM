# Test array push and pop
# BUG: These builtins are documented in docs/SPEC.md but are NOT currently
# implemented in src/svm/sgvm_vm.sage's setup_builtins or call_builtin handlers.
# Expect: "Error: Callee not a function or builtin name"
var a = [1, 2]
print "Initial array: " + str(a)
push(a, 3)
print "After push(3): " + str(a)
var x = pop(a)
print "Popped: " + str(x)
print "After pop(): " + str(a)
