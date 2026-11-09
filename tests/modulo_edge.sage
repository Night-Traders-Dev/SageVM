# Test OP_MOD (%) modulo operator across integers, floats, zero divisor, and invalid/nil operands

print "--- Modulo Integers ---"
print 10 % 3
print 20 % 5
print 7 % 10
print (-10) % 3
print 10 % (-3)

print "--- Modulo Floating Point ---"
print 10.5 % 3.0
print 7.25 % 2.5

print "--- Modulo Edge & Invalid Operands ---"
print 10 % 0
print nil % 5
print 5 % nil
