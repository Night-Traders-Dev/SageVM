# Test upper() and lower() string builtins under normal and edge conditions.
# NOTE: Passing non-string arguments (e.g. upper(123) or lower(true)) returns nil in SVM.

print "--- Normal upper and lower ---"
print "upper('hello world'): " + upper("hello world")
print "lower('HELLO WORLD'): " + lower("HELLO WORLD")
print "upper('Mixed Case 123!'): " + upper("Mixed Case 123!")
print "lower('Mixed Case 123!'): " + lower("Mixed Case 123!")

print "--- Empty string ---"
print "upper(''): " + upper("")
print "lower(''): " + lower("")

print "--- Non-string / nil arguments ---"
print "upper(nil) == nil: " + str(upper(nil) == nil)
print "lower(nil) == nil: " + str(lower(nil) == nil)
print "upper(123) == nil: " + str(upper(123) == nil)
print "lower(true) == nil: " + str(lower(true) == nil)
