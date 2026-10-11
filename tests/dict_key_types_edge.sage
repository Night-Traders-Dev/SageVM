# Test dictionary key indexing with non-string types, string key coercion,
# reflection builtins, and missing key evaluation.
# SUSPECTED VM CONSTRAINT: Direct non-string key indexing (such as integer or boolean keys)
# evaluates to nil in SVM due to string key lookup expectations.

print "--- Non-string Key Indexing (Suspected VM Constraint) ---"
var d = {}
d[1] = "one"
d[true] = "boolean_true"

print "d[1]: " + str(d[1])
print "d[true]: " + str(d[true])
print "dict_has(d, 1): " + str(dict_has(d, 1))

print "--- Explicit String Key Coercion ---"
d[str(1)] = "one_str"
d[str(true)] = "true_str"

print "d['1']: " + str(d["1"])
print "d['true']: " + str(d["true"])
print "dict_has(d, '1'): " + str(dict_has(d, "1"))
print "dict_keys(d): " + str(dict_keys(d))
print "dict_values(d): " + str(dict_values(d))

print "--- Missing Keys ---"
print "d['missing']: " + str(d["missing"])
