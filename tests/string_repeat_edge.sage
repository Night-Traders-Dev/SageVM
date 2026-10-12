# Test string multiplication (OP_MUL) and str_repeat edge cases

print "--- Standard string repetition ---"
print "abc" * 3
print 4 * "xy"

print "--- Zero and negative multipliers ---"
print "hello" * 0
print "hello" * -3
print 0 * "world"

print "--- Float multiplier ---"
print "code" * 2.5

print "--- Empty string repetition ---"
print "" * 5
print "" * 0

print "--- Chained repetition and expressions ---"
print ("a" + "b") * (1 + 2)
print 2 * ("x" * 2)

print "--- Nil operands ---"
print nil * 3
print "a" * nil
