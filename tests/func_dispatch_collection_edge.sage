proc add_fn(a, b):
    return a + b

proc sub_fn(a, b):
    return a - b

proc mul_fn(a, b):
    return a * b

print "--- Function Array Dispatch ---"
var funcs = [add_fn, sub_fn, mul_fn]
var f0 = funcs[0]
print f0(10, 5)
var f1 = funcs[1]
print f1(10, 5)
var f2 = funcs[2]
print f2(10, 5)

print "--- Function Dict Dispatch ---"
var ops = {"add": add_fn, "sub": sub_fn}
var op_add = ops["add"]
print op_add(20, 8)
var op_sub = ops["sub"]
print op_sub(20, 8)

print "--- Function Reassignment in Dict ---"
ops["add"] = mul_fn
var op_add2 = ops["add"]
print op_add2(20, 8)

print "--- Higher-Order Collection Execution ---"
# Note: In SVM, invoking a function handle binding directly inside a loop body
# (`for f in fn_list: f(...)`) fails with `Error: Callee not a function or builtin name`
# because OP_CALL expects a string constant or global handle.
proc apply_all(fn_list, x, y):
    var res = []
    for f in fn_list:
        push(res, f(x, y))
    return res

var results = apply_all([add_fn, sub_fn, mul_fn], 12, 4)
print results[0]
print results[1]
print results[2]
