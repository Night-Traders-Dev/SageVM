# Test function argument binding, missing args, extra args, and return behavior

proc greet(name, greeting):
    return str(name) + ", " + str(greeting)

print "--- Standard Call ---"
print greet("Alice", "Hi")

print "--- Missing Second Argument ---"
print greet("Bob")

proc calc(a, b):
    return a * 2 + b

print "--- Extra Arguments (Ignored) ---"
print calc(5, 10, 99, 100)

proc early_return(x):
    if x < 0:
        return "negative"
    if x == 0:
        return "zero"
    return "positive"

print "--- Early Returns ---"
print early_return(-5)
print early_return(0)
print early_return(10)
