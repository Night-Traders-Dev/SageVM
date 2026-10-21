# Function dispatch via collection indexing and higher-order calls

proc add(a, b):
    return a + b

proc sub(a, b):
    return a - b

proc mul(a, b):
    return a * b

print "--- Function References in Array ---"
var ops_arr = [add, sub, mul]
print ops_arr[0](10, 5)
print ops_arr[1](10, 5)
print ops_arr[2](10, 5)

print "--- Function References in Dictionary ---"
var ops_dict = {
    "add": add,
    "sub": sub,
    "mul": mul
}
print ops_dict["add"](20, 4)
print ops_dict["sub"](20, 4)
print ops_dict["mul"](20, 4)

print "--- Reassignment of Function Handles in Collections ---"
ops_arr[0] = sub
print ops_arr[0](10, 5)

print "--- Higher-Order Function Collection Dispatch ---"
proc execute_op(op_func, x, y):
    return op_func(x, y)

print execute_op(ops_dict["mul"], 6, 7)

print "--- Missing Function Reference in Dict ---"
var missing = ops_dict["div"]
print missing
