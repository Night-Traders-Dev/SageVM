# Test recursive function calls (OP_CALL, OP_RETURN), parameter binding across frames,
# mutual recursion, accumulator recursion, base cases, and boundary conditions.

proc fact(n):
    if n <= 1:
        return 1
    return n * fact(n - 1)

proc fib(n):
    if n <= 0:
        return 0
    if n == 1:
        return 1
    return fib(n - 1) + fib(n - 2)

proc is_even(n):
    if n == 0:
        return true
    if n < 0:
        return is_even(-n)
    return is_odd(n - 1)

proc is_odd(n):
    if n == 0:
        return false
    if n < 0:
        return is_odd(-n)
    return is_even(n - 1)

proc sum_acc(n, acc):
    if n <= 0:
        return acc
    return sum_acc(n - 1, acc + n)

print "--- Factorial ---"
print "fact(0): " + str(fact(0))
print "fact(1): " + str(fact(1))
print "fact(5): " + str(fact(5))
print "fact(7): " + str(fact(7))

print "--- Fibonacci ---"
print "fib(0): " + str(fib(0))
print "fib(1): " + str(fib(1))
print "fib(6): " + str(fib(6))
print "fib(10): " + str(fib(10))

print "--- Mutual Recursion ---"
print "is_even(0): " + str(is_even(0))
print "is_even(4): " + str(is_even(4))
print "is_even(7): " + str(is_even(7))
print "is_odd(0): " + str(is_odd(0))
print "is_odd(5): " + str(is_odd(5))
print "is_odd(-3): " + str(is_odd(-3))

print "--- Accumulator Recursion ---"
print "sum_acc(0, 0): " + str(sum_acc(0, 0))
print "sum_acc(10, 0): " + str(sum_acc(10, 0))
