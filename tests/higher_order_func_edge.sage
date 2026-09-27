# Test higher-order functions, first-class functions, and collection invocations edge cases

proc inc(x):
    return x + 1

proc mult(x):
    return x * 3

proc is_odd(x):
    return (x % 2) != 0

proc apply_fn(f, arg):
    return f(arg)

print "--- Passing Function as Argument ---"
print "apply_fn(inc, 10): " + str(apply_fn(inc, 10))
print "apply_fn(mult, 10): " + str(apply_fn(mult, 10))

print "--- Higher-Order Map / Filter ---"
proc map_list(f, items):
    var res = []
    var i = 0
    while i < len(items):
        push(res, f(items[i]))
        i = i + 1
    return res

proc filter_list(f, items):
    var res = []
    var i = 0
    while i < len(items):
        if f(items[i]):
            push(res, items[i])
        i = i + 1
    return res

var nums = [1, 2, 3, 4, 5]
var mapped = map_list(inc, nums)
print "mapped len: " + str(len(mapped))
print "mapped[0]: " + str(mapped[0])
print "mapped[4]: " + str(mapped[4])

var filtered = filter_list(is_odd, nums)
print "filtered len: " + str(len(filtered))
print "filtered[0]: " + str(filtered[0])
print "filtered[1]: " + str(filtered[1])
print "filtered[2]: " + str(filtered[2])

print "--- Functions Stored in Array & Dictionary ---"
var funcs = [inc, mult]
var f0 = funcs[0]
var f1 = funcs[1]
print "f0(5): " + str(f0(5))
print "f1(5): " + str(f1(5))

var table = {"step": inc, "scale": mult}
var f_step = table["step"]
var f_scale = table["scale"]
print "f_step(20): " + str(f_step(20))
print "f_scale(20): " + str(f_scale(20))

print "--- Returning Function from Factory ---"
proc make_op(mode):
    if mode == "add":
        return inc
    return mult

var op = make_op("add")
print "op(100): " + str(op(100))

print "--- Builtin Functions as Parameters ---"
print "apply_fn(upper, 'hello'): " + str(apply_fn(upper, "hello"))
print "apply_fn(lower, 'WORLD'): " + str(apply_fn(lower, "WORLD"))
