# Test bitwise shift edge cases

print "1. Shift by zero:"
print 10 << 0
print 10 >> 0

print "2. Shift negative values:"
print -10 << 1
print -10 >> 1

print "3. Shift with nil:"
print nil << 2
print 10 << nil

print "4. Shift float values:"
# The VM casts float values to int internally on standard operations if possible, or handles them.
# Let's see what happens with float values.
print 10.5 << 1
print 10 >> 1.5

print "5. Shift with negative counts:"
# This is a potential edge case.
print 10 << -1
print 10 >> -1
