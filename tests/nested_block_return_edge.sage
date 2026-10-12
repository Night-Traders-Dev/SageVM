# Test early returns from nested block environments, loops, conditionals, and try blocks

proc return_from_nested_if(x, y):
    if x > 0:
        if y > 0:
            return "both positive"
        else:
            return "x positive"
    else:
        return "x non-positive"
    return "unreachable"

print "return_from_nested_if(1, 1): " + return_from_nested_if(1, 1)
print "return_from_nested_if(1, -1): " + return_from_nested_if(1, -1)
print "return_from_nested_if(-1, 0): " + return_from_nested_if(-1, 0)

proc return_from_while_loop(limit):
    var count = 0
    while count < 100:
        count = count + 1
        if count == limit:
            return count
    return -1

print "return_from_while_loop(5): " + str(return_from_while_loop(5))
print "return_from_while_loop(200): " + str(return_from_while_loop(200))

proc return_from_nested_try(should_fail):
    try:
        var val = 10
        if should_fail:
            raise "error_in_try"
        else:
            return "success_in_try: " + str(val)
    catch err:
        return "caught_err: " + str(err)
    return "unreachable"

print return_from_nested_try(false)
print return_from_nested_try(true)

proc test_stack_balance():
    var a = "A"
    var b = "B"
    var r1 = return_from_nested_if(2, 3)
    var r2 = return_from_while_loop(3)
    var r3 = return_from_nested_try(false)
    return a + "_" + b + "_" + r1 + "_" + str(r2) + "_" + r3

print "Stack balance verification: " + test_stack_balance()
