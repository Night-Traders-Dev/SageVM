# Test bitwise operators (OP_BIT_AND, OP_BIT_OR, OP_BIT_XOR, OP_BIT_NOT, OP_SHIFT_LEFT, OP_SHIFT_RIGHT)
# covering normal behavior, negative numbers, zero masks, floats, nil, and chained expressions.

print "--- Bitwise AND / OR / XOR / NOT with Negative Numbers ---"
print -1 & 255
print -10 | 5
print -1 ^ 15
print ~(-1)
print ~0

print "--- Bitwise Operations with Zero Masks ---"
print 42 & 0
print 42 | 0
print 42 ^ 0

print "--- Bitwise Operations with Floats and Nil ---"
print 3.14 & 2
print nil & 5
print 5 | nil

print "--- Bitwise Shifts ---"
print 1 << 0
print 1 << 8
print 256 >> 4
print 0 >> 5

print "--- Chained Bitwise Expressions ---"
let val = (~0 & 15) ^ (1 << 2)
print val
