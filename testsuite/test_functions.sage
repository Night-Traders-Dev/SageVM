# test_functions.sage
# Tests function definition, call, and return values.
# Expected output:
#   fib(0)=0
#   fib(1)=1
#   fib(7)=13
#   factorial(5)=120

proc fib(n):
    if n <= 1:
        return n
    return fib(n - 1) + fib(n - 2)

proc factorial(n):
    if n <= 1:
        return 1
    return n * factorial(n - 1)

print("fib(0)=" + str(fib(0)))
print("fib(1)=" + str(fib(1)))
print("fib(7)=" + str(fib(7)))
print("factorial(5)=" + str(factorial(5)))
