# Test relational (<, <=, >, >=) and equality (==, !=) comparison opcodes
# SVM comparison semantics:
# OP_EQUAL / OP_NOT_EQUAL: Uses equal_val deep comparison logic
# OP_LESS / OP_LESS_EQUAL / OP_GREATER / OP_GREATER_EQUAL: Returns numeric comparison if both operands are numbers, otherwise returns false.

print "--- Numeric Comparisons ---"
print "10 < 20: " + str(10 < 20)
print "20 <= 20: " + str(20 <= 20)
print "30 > 15: " + str(30 > 15)
print "15 >= 15: " + str(15 >= 15)
print "-5 < 0: " + str(-5 < 0)
print "3.14 > 2.71: " + str(3.14 > 2.71)

print "--- Numeric Boundary and False Conditions ---"
print "20 < 10: " + str(20 < 10)
print "25 <= 20: " + str(25 <= 20)
print "10 > 30: " + str(10 > 30)
print "10 >= 15: " + str(10 >= 15)

print "--- Equality and Inequality ---"
print "10 == 10: " + str(10 == 10)
print "10 != 20: " + str(10 != 20)
print "'abc' == 'abc': " + str("abc" == "abc")
print "'abc' != 'xyz': " + str("abc" != "xyz")
print "nil == nil: " + str(nil == nil)
print "true != false: " + str(true != false)
print "[1, 2] == [1, 2]: " + str([1, 2] == [1, 2])

print "--- Non-Numeric Relational Comparisons (SVM Fallback Behavior) ---"
print "'a' < 'b': " + str("a" < "b")
print "'b' > 'a': " + str("b" > "a")
print "true < false: " + str(true < false)
print "nil < 0: " + str(nil < 0)
print "[1] < [2]: " + str([1] < [2])

print "--- Mixed Type Equality ---"
print "10 == '10': " + str(10 == "10")
print "0 == false: " + str(0 == false)
print "nil == false: " + str(nil == false)
