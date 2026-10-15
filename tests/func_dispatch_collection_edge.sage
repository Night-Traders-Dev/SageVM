# Test function references stored in arrays and dictionaries, dispatching via
# indexing/properties, reference reassignment, higher-order function dispatch,
# and edge cases.

proc square(x):
    return x * x

proc double_num(x):
    return x * 2

proc apply_fn(fn, val):
    return fn(val)

print "--- Function References in Array & Dict ---"
var handlers = [square, double_num]
print handlers[0](5)
print handlers[1](5)

var registry = {"sq": square, "dbl": double_num}
print registry["sq"](4)
print registry["dbl"](4)

print "--- Higher-Order Dispatch from Collections ---"
print apply_fn(handlers[0], 6)
print apply_fn(registry["dbl"], 6)

print "--- Reassignment in Collections ---"
handlers[0] = double_num
print handlers[0](5)

registry["sq"] = double_num
print registry["sq"](4)
