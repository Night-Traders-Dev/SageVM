# Higher-order functions and variable-bound functions (OP_LOAD_FUNCTION)

proc square(x):
    return x * x

var sq = square
print "Square of 5 (via variable):"
print sq(5)

proc apply(f, val):
    return f(val)

print "Applying square via apply(f, 5):"
print apply(square, 5)

proc get_adder(n):
    # Testing returning a function
    # Note: SVM lacks closures, so this adder can only use its own args
    proc adder(x, y):
        return x + y
    return adder

var add = get_adder(10)
print "Result of add(5, 3):"
print add(5, 3)
