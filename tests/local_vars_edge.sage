# Test local variable operations (OP_GET_LOCAL, OP_SET_LOCAL), parameter bindings,
# loop reassignments, shadowing, and uninitialized local slot access.

var global_x = 100
var global_y = 200

proc test_locals(a, b):
    var x = a + 10
    var y = b * 2
    print "Initial locals x, y: " + str(x) + ", " + str(y)

    # Reassignment in a loop
    var i = 0
    var sum = 0
    while i < 5:
        sum = sum + i
        i = i + 1
    print "Loop sum, final i: " + str(sum) + ", " + str(i)

    # Shadowing global variables
    var global_x = 999
    print "Local shadow global_x: " + str(global_x)
    return x + y + sum

print "--- Local Variable Execution ---"
print "Function result: " + str(test_locals(5, 10))
print "Global x unchanged: " + str(global_x)
print "Global y unchanged: " + str(global_y)

proc nested_param_args(arg0, arg1, arg2):
    print "arg0: " + str(arg0) + ", arg1: " + str(arg1) + ", arg2: " + str(arg2)

print "--- Parameter Binding ---"
nested_param_args("alpha", "beta", "gamma")
nested_param_args(1, nil, true)
