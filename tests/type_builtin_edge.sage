import math

# Test type() builtin behavior on primitive types, collections, functions, and bridged modules
print "Testing type() builtin function..."
print "type(123): " + type(123)
print "type(3.14): " + type(3.14)
print "type(\"hello\"): " + type("hello")
print "type(true): " + type(true)
print "type(false): " + type(false)
print "type(nil): " + type(nil)
print "type([]): " + type([])
print "type({}): " + type({})

# Documented SVM gap: Tuples return "array" under SVM backend
print "type((1, 2)): " + type((1, 2))

proc sample():
    return 42

# Documented SVM gap: User functions and native modules return "dict" under SVM backend
print "type(sample): " + type(sample)
print "type(math): " + type(math)

# Documented SVM gap: Builtin string handlers return "string" under SVM backend
print "type(type): " + type(type)
