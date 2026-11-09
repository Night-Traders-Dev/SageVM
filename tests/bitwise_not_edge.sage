# Test OP_BIT_NOT (~) bitwise NOT operator across integers, expressions, double negation, and nil handling

print "--- Bitwise NOT Integers ---"
print ~0
print ~1
print ~(-1)
print ~100
print ~(-101)

print "--- Bitwise NOT Expressions & Double Negation ---"
var x = 15
print ~(x + 5)
print ~~x

print "--- Bitwise NOT Edge Values ---"
print ~nil
