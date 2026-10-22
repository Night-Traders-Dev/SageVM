# Test dict reflection builtins (dict_keys, dict_values, dict_has) across
# empty dicts, dicts with non-string keys, nil value mappings, key mutations,
# missing keys, and key/value loop iterations.

let empty = {}
print "--- Empty Dictionary ---"
print "empty keys len: " + str(len(dict_keys(empty)))
print "empty values len: " + str(len(dict_values(empty)))
print "empty has 'a': " + str(dict_has(empty, "a"))

let d = {"alpha": 100, "beta": 200, "gamma": 300}
print "--- Key and Value Retrieval ---"
let keys = dict_keys(d)
let vals = dict_values(d)
print "keys count: " + str(len(keys))
print "values count: " + str(len(vals))

print "--- Dict Key Iteration in While Loop ---"
var sum = 0
var i = 0
while i < len(keys):
    let k = keys[i]
    if dict_has(d, k):
        sum = sum + d[k]
    i = i + 1
print "dict value sum: " + str(sum)

print "--- Non-string Key and Nil Value Handling ---"
let d_mixed = {}
d_mixed["str_key"] = "hello"
d_mixed[42] = "number_key"
d_mixed["nil_val"] = nil

print "has str_key: " + str(dict_has(d_mixed, "str_key"))
print "has 42: " + str(dict_has(d_mixed, 42))
print "has nil_val: " + str(dict_has(d_mixed, "nil_val"))
print "has missing_key: " + str(dict_has(d_mixed, "missing_key"))
print "d_mixed['nil_val'] == nil: " + str(d_mixed["nil_val"] == nil)

print "--- Nil and Primitive Target Reflection Fallbacks ---"
print "nil keys len: " + str(len(dict_keys(nil)))
print "nil values len: " + str(len(dict_values(nil)))
print "nil has 'a': " + str(dict_has(nil, "a"))
print "array keys len: " + str(len(dict_keys([1, 2, 3])))
print "number keys len: " + str(len(dict_keys(999)))
