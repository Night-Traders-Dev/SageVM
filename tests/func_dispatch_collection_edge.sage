# Test function dispatch stored in collections (arrays and dicts)

proc add(a, b):
    return a + b

proc sub(a, b):
    return a - b

proc mul(a, b):
    return a * b

print "1. Array function dispatch:"
var ops_arr = [add, sub, mul]
print ops_arr[0](10, 5)
print ops_arr[1](10, 5)
print ops_arr[2](10, 5)

print "2. Dict function dispatch:"
var ops_dict = {"+": add, "-": sub, "*": mul}
print ops_dict["+"](20, 4)
print ops_dict["-"](20, 4)
print ops_dict["*"](20, 4)

print "3. Function reassignment in collection:"
ops_arr[1] = add
print ops_arr[1](10, 5)

print "4. Higher-order collection dispatch:"
proc run_op(handler, x, y):
    return handler(x, y)

print run_op(ops_dict["+"], 15, 3)

print "5. Missing key lookup:"
var missing_func = ops_dict["/"]
print missing_func
