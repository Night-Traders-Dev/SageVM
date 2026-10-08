# Test nested function scope chain, global fallback, parameter shadowing,
# and non-lexical scope behavior in SVM.

var global_val = "I am global"

proc test_outer_inner():
    var outer_var = "outer local"
    proc inner():
        # Unbound outer local resolves to nil in SVM (no lexical closure capture)
        print "inner outer_var: " + str(outer_var)
        # Global variable fallback works
        print "inner global_val: " + str(global_val)
    inner()

print "--- Nested Unbound Scope Resolution ---"
test_outer_inner()

proc test_param_pass(x):
    proc inner_with_param(p):
        return "param: " + str(p)
    return inner_with_param(x)

print "--- Explicit Parameter Passing to Nested Function ---"
print test_param_pass("passed value")

proc test_shadowing(global_val):
    print "shadowed param: " + str(global_val)

print "--- Parameter Shadowing Global ---"
test_shadowing("local param value")
print "global_val after call: " + str(global_val)
