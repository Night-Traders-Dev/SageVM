# Test exception unwinding across nested function calls, re-raising, and return inside try blocks.

proc level3(should_raise):
    print "Level 3 entering"
    if should_raise:
        raise ["ERR_LVL3", 300]
    return "Level 3 success"

proc level2(should_raise):
    print "Level 2 entering"
    var res = level3(should_raise)
    print "Level 2 exiting"
    return res

proc level1(should_raise):
    print "Level 1 entering"
    try:
        var res = level2(should_raise)
        print "Level 1 res: " + str(res)
    catch err:
        print "Level 1 caught: " + str(err)
        raise ["ERR_LVL1", err]
    return "Level 1 done"

print "--- Case 1: Normal execution without raise ---"
var r1 = level1(false)
print "Result 1: " + str(r1)

print "--- Case 2: Raise from level 3, caught in level 1, re-raised to main ---"
try:
    var r2 = level1(true)
    print "Result 2: " + str(r2)
catch main_err:
    print "Main caught re-raised: " + str(main_err)

print "--- Case 3: Return inside try block ---"
proc try_return(x):
    try:
        if x > 0:
            return "positive_return"
        raise "negative_val"
    catch e:
        return "caught_" + str(e)

print try_return(10)
print try_return(-5)
