# Test bitwise operators edge cases (OP_BIT_AND, OP_BIT_OR, OP_BIT_XOR, OP_BIT_NOT)

print "--- Bitwise operations with floats ---"
print "5.5 & 3.2: " + str(5.5 & 3.2)
print "5.5 | 3.2: " + str(5.5 | 3.2)
print "5.5 ^ 3.2: " + str(5.5 ^ 3.2)
print "~5.5: " + str(~5.5)

print "--- Bitwise operations with negative values ---"
print "~-1: " + str(~-1)
print "~0: " + str(~0)
print "-5 & 3: " + str(-5 & 3)

print "--- Bitwise operations with nil ---"
print "10 & nil: " + str(10 & nil)
print "nil | 5: " + str(nil | 5)
print "nil ^ 10: " + str(nil ^ 10)
print "~nil: " + str(~nil)
