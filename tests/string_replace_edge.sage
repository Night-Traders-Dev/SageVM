# String replace builtin edge cases
print "--- Normal replace ---"
print replace("hello world", "world", "sage")

print "--- Deletion replace (new is empty) ---"
print replace("foo-bar-baz", "-", "")

print "--- Replace with multiple occurrences ---"
print replace("a b c a b c", "a", "x")

print "--- Replace entire string ---"
print replace("exact", "exact", "replaced")

print "--- Replace non-existent ---"
print replace("sample text", "missing", "found")

print "--- Replace with escape characters ---"
print replace("line1\nline2", "\n", " | ")

print "--- Replace empty string target ---"
print replace("abc", "", "_")

print "--- Replace in empty string ---"
print replace("", "a", "b")

print "--- Replace with nil arguments ---"
print replace(nil, "a", "b")
print replace("hello", nil, "x")
print replace("hello", "l", nil)
