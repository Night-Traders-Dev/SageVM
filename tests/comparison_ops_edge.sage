# Test relational and equality comparison opcodes across various data types and edge conditions under SVM.

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
