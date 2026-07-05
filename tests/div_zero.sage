print "Testing division by zero:"
var a = 10 / 0
print a == nil

print "Testing modulo by zero:"
var b = 10 % 0
print b == nil

print "Testing division by zero with variables:"
var zero = 0
var c = 5 / zero
print c == nil
