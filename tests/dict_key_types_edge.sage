# Test non-string dictionary keys and edge cases in SVM

var d = {}

# String key indexing vs non-string key indexing
d[str(1)] = "one"
d[str(42)] = "forty-two"
print "d[str(1)]: " + str(d[str(1)])
print "d[str(42)]: " + str(d[str(42)])

# Non-string keys evaluate to nil in SVM direct indexing
d[1] = "numeric_one"
d[3.14] = "pi"
d[true] = "yes"
d[false] = "no"
d[nil] = "null_val"

print "d[1]: " + str(d[1])
print "d[3.14]: " + str(d[3.14])
print "d[true]: " + str(d[true])
print "d[false]: " + str(d[false])
print "d[nil]: " + str(d[nil])

# Reflection builtins on non-string keys
print "dict_has(d, 42): " + str(dict_has(d, 42))
print "dict_has(d, str(42)): " + str(dict_has(d, str(42)))
print "dict_has(d, 999): " + str(dict_has(d, 999))
print "dict_has(d, true): " + str(dict_has(d, true))

# Dict keys/values
var keys = dict_keys(d)
var vals = dict_values(d)
print "dict_keys len: " + str(len(keys))
print "dict_values len: " + str(len(vals))

# Missing key returns nil
print "d[\"missing\"] == nil: " + str(d["missing"] == nil)
