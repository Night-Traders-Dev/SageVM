# Test multi-frame exception stack unwinding
# Checks that exception unwinding correctly pops VM call frames and restores state.

proc func_c():
    print "Inside func_c, about to raise"
    raise "Error from C"
    print "Should not print this in C"

proc func_b():
    print "Inside func_b, calling func_c"
    func_c()
    print "Should not print this in B"

proc func_a():
    print "Inside func_a, calling func_b"
    try:
        func_b()
    catch e:
        print "Caught in func_a: " + str(e)
    print "Completed func_a handler"

print "Start test"
func_a()
print "End test"
