# Test function references stored in arrays and dictionaries, dispatching from collections, and boundary cases

proc add(a, b):
    return a + b

proc sub(a, b):
    return a - b

proc mul(a, b):
    return a * b

print "--- Function references in array ---"
var funcs = [add, sub, mul]
print "funcs len: " + str(len(funcs))
print "funcs[0](10, 5): " + str(funcs[0](10, 5))
print "funcs[1](10, 5): " + str(funcs[1](10, 5))
print "funcs[2](10, 5): " + str(funcs[2](10, 5))

print "--- Function references in dictionary via index lookup ---"
var ops = {"add_op": add, "sub_op": sub}
print "ops['add_op'](20, 30): " + str(ops["add_op"](20, 30))
print "ops['sub_op'](50, 15): " + str(ops["sub_op"](50, 15))

print "--- Reassigning function in dictionary ---"
ops["calc"] = mul
print "ops['calc'](6, 7): " + str(ops["calc"](6, 7))

print "--- Higher order function with collection lookup ---"
proc apply_op(op_list, idx, x, y):
    var fn = op_list[idx]
    return fn(x, y)

print "apply_op(funcs, 2, 8, 9): " + str(apply_op(funcs, 2, 8, 9))

print "--- Invoking nil / missing function entry ---"
var empty_dict = {}
var missing_fn = empty_dict["missing"]
print "missing_fn == nil: " + str(missing_fn == nil)
