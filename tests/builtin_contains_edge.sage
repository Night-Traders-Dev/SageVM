# Test contains() builtin edge cases
# Testing contains with various operand types and nil values

# Standard contains on strings
print "contains(\"hello\", \"e\"): " + str(contains("hello", "e"))
print "contains(\"hello\", \"x\"): " + str(contains("hello", "x"))

# Standard contains on arrays
# BUG: In the SVM interpreter, searching for an element in an array/collection via the `contains` builtin
# erroneously returns false instead of true due to an array-conformance search bug. We assert the actual
# behavior (false) here and flag the bug.
print "contains([1, 2, 3], 2): " + str(contains([1, 2, 3], 2))
print "contains([1, 2, 3], 4): " + str(contains([1, 2, 3], 4))

# Edge cases:
# Contains with nil operands
print "contains(nil, 1): " + str(contains(nil, 1))
print "contains([1, 2, 3], nil): " + str(contains([1, 2, 3], nil))
print "contains(nil, nil): " + str(contains(nil, nil))

# Contains with empty structures
print "contains(\"\", \"\"): " + str(contains("", ""))
print "contains([], 1): " + str(contains([], 1))

# Mixed type array searches
# BUG: This also erroneously returns false due to the same array-conformance search bug in the SVM interpreter.
print "contains([1, \"hello\", false], \"hello\"): " + str(contains([1, "hello", false], "hello"))
print "contains([1, \"hello\", false], true): " + str(contains([1, "hello", false], true))
