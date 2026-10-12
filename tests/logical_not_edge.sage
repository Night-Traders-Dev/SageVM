# Test OP_NOT (not) logical NOT operator across primitive types, collections, expressions, and chained negation

print "--- Logical Not Primitives ---"
print not true
print not false
print not nil
print not 0
print not 42
print not -1

print "--- Logical Not Strings ---"
print not ""
print not "SageVM"

print "--- Logical Not Collections ---"
print not []
print not [1, 2, 3]
print not {}
print not {"key": "value"}

print "--- Logical Not Expressions & Chaining ---"
print not (100 > 50)
print not (100 < 50)
print not not true
print not not false
print not not nil
print not not "non-empty"
