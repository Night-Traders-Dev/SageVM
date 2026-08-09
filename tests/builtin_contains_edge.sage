# Test contains() builtin with various edge cases and types.
# SUSPECTED BUG: The contains() builtin on the SVM backend always returns false
# for array targets (e.g. searching for an element in an array), even if the
# element is present. However, it functions correctly for string targets.

print "Testing contains builtin edge cases..."

# 1. Strings
print "String with substring:"
print contains("abcdef", "cd")
print "String with missing substring:"
print contains("abcdef", "xyz")
print "String with empty string:"
print contains("abcdef", "")
print "String looking for non-string (integer):"
print contains("abcdef", 123)

# 2. Arrays
print "Array with element present:"
print contains(["apple", "banana", "cherry"], "banana")
print "Array with element missing:"
print contains(["apple", "banana", "cherry"], "orange")
print "Array containing nil:"
print contains(["apple", nil, "cherry"], nil)
print "Array looking for nil when missing:"
print contains(["apple", "banana"], nil)

# 3. Edge / Error Cases: Nil arguments
print "First argument nil:"
print contains(nil, "apple")
print "Second argument nil:"
print contains(["apple", "banana"], nil)
print "Both arguments nil:"
print contains(nil, nil)

# 4. Other types (dictionaries, numbers)
print "Dictionary target (not supported/returns false):"
print contains({"a": 1, "b": 2}, "a")
print "Number target:"
print contains(42, 2)
