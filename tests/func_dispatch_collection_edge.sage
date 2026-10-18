print "--- Function Dispatch from Array ---"
proc add(a, b):
    return a + b

proc sub(a, b):
    return a - b

proc mul(a, b):
    return a * b

var ops_arr = [add, sub, mul]
print ops_arr[0](10, 5)
print ops_arr[1](10, 5)
print ops_arr[2](10, 5)

print "--- Function Dispatch from Dictionary ---"
var ops_dict = {"add": add, "sub": sub, "mul": mul}
print ops_dict["add"](20, 4)
print ops_dict["sub"](20, 4)
print ops_dict["mul"](20, 4)

print "--- Reassigning Functions in Collections ---"
ops_arr[1] = mul
print ops_arr[1](10, 5)

ops_dict["sub"] = add
print ops_dict["sub"](20, 4)

print "--- Higher-Order Dispatch with Collection Handles ---"
proc apply_op(fn_handle, x, y):
    return fn_handle(x, y)

print apply_op(ops_arr[0], 7, 3)
print apply_op(ops_dict["sub"], 7, 3)

print "--- Nested Collection Dispatch ---"
var matrix_ops = [
    [add, sub],
    [mul, add]
]
print matrix_ops[0][0](100, 50)
print matrix_ops[0][1](100, 50)
print matrix_ops[1][0](100, 50)
