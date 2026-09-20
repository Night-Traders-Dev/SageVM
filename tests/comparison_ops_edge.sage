# Test relational (<, <=, >, >=) and equality (==, !=) comparison opcodes on boundary types.

print "--- Numeric relational comparisons ---"
print "-10 < -5: " + str(-10 < -5)
print "-5 < -10: " + str(-5 < -10)
print "0.5 <= 0.5: " + str(0.5 <= 0.5)
print "100 > 99: " + str(100 > 99)
print "0 >= 0: " + str(0 >= 0)

# NOTE / SUSPECTED BUG: In OP_LESS, OP_GREATER, OP_LESS_EQUAL, and OP_GREATER_EQUAL (sgvm_vm.sage),
# relational comparisons evaluate to false unless both operands are numbers (type == "number").
# Comparing strings (e.g., 'abc' < 'def') or mixed types returns false instead of lexicographical ordering.
print "--- String relational comparisons ---"
print "'abc' < 'def': " + str("abc" < "def")
print "'apple' > 'banana': " + str("apple" > "banana")

print "--- Mixed type relational comparisons (String vs Number) ---"
print "'10' < 20: " + str("10" < 20)
print "20 > '10': " + str(20 > "10")

print "--- Relational comparisons involving nil ---"
print "nil < 5: " + str(nil < 5)
print "5 <= nil: " + str(5 <= nil)
print "nil > 0: " + str(nil > 0)
print "0 >= nil: " + str(0 >= nil)

print "--- Relational comparisons involving booleans ---"
print "true > false: " + str(true > false)
print "false <= true: " + str(false <= true)

print "--- Equality across types and collections ---"
print "5 == 5: " + str(5 == 5)
print "5 == '5': " + str(5 == "5")
print "nil == nil: " + str(nil == nil)
print "nil == false: " + str(nil == false)
print "true == false: " + str(true == false)
print "[1, 2] == [1, 2]: " + str([1, 2] == [1, 2])
print "[1, 2] == [1, 3]: " + str([1, 2] == [1, 3])
print "{\"a\": 1} == {\"a\": 1}: " + str({"a": 1} == {"a": 1})
print "{\"a\": 1} == {\"a\": 2}: " + str({"a": 1} == {"a": 2})
print "[1, 2] == (1, 2): " + str([1, 2] == (1, 2))

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


print "--- Numeric Comparisons ---"
print "10 < 20: " + str(10 < 20)
print "20 <= 20: " + str(20 <= 20)
print "30 > 15: " + str(30 > 15)
print "15 >= 15: " + str(15 >= 15)
print "10 == 10: " + str(10 == 10)
print "10 != 20: " + str(10 != 20)

print "--- String Comparisons ---"
print "'apple' == 'apple': " + str("apple" == "apple")
print "'apple' != 'banana': " + str("apple" != "banana")
# Relational comparison on strings in SVM evaluates via tonumber fastpath/fallback
print "'apple' < 'banana': " + str("apple" < "banana")

print "--- Nil and Mixed-Type Equality ---"
print "nil == nil: " + str(nil == nil)
print "nil != 0: " + str(nil != 0)
print "false == false: " + str(false == false)
print "true != false: " + str(true != false)
print "10 == '10': " + str(10 == "10")

print "--- Collection Equality ---"
print "[1, 2] == [1, 2]: " + str([1, 2] == [1, 2])
print "[1, 2] != [3, 4]: " + str([1, 2] != [3, 4])
