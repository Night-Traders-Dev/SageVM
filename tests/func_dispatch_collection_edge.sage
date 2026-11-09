# Test function references in arrays and dictionaries, dispatch via index/key lookup,
# function handle reassignment, higher-order collection dispatch, and boundary checks.

proc add(a, b):
    return a + b

proc sub(a, b):
    return a - b

proc mul(a, b):
    return a * b

proc double_val(x):
    return x * 2

print "--- Function References in Arrays ---"
var funcs = [add, sub, mul]
print "funcs[0](10, 5): " + str(funcs[0](10, 5))
print "funcs[1](10, 5): " + str(funcs[1](10, 5))
print "funcs[2](10, 5): " + str(funcs[2](10, 5))

print "--- Function References in Dictionaries ---"
var ops = {"plus": add, "minus": sub, "times": mul}
print "ops['plus'](20, 4): " + str(ops["plus"](20, 4))
print "ops['minus'](20, 4): " + str(ops["minus"](20, 4))
print "ops['times'](20, 4): " + str(ops["times"](20, 4))

print "--- Function Reassignment in Dictionaries ---"
ops["plus"] = mul
print "ops['plus'](20, 4) after reassignment to mul: " + str(ops["plus"](20, 4))

print "--- Higher-Order Collection Pipeline Dispatch ---"
proc pipeline_apply(pipeline, initial_val):
    var val = initial_val
    var i = 0
    while i < len(pipeline):
        let f = pipeline[i]
        val = f(val)
        i = i + 1
    return val

proc add_ten(x):
    return x + 10

proc square_val(x):
    return x * x

var pipe = [add_ten, double_val, square_val]
print "pipeline_apply([add_ten, double_val, square_val], 3): " + str(pipeline_apply(pipe, 3))

print "--- Missing or Non-Function Handle Lookup ---"
print "ops['missing'] == nil: " + str(ops["missing"] == nil)
print "funcs[10] == nil: " + str(funcs[10] == nil)
