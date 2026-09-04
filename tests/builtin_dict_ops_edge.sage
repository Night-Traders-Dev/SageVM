# Test dict_has(), dict_keys(), and dict_values() dictionary builtins under normal and edge conditions.

var d = {}
d["a"] = 10
d["b"] = 20

print "--- dict_has ---"
print "dict_has(d, 'a'): " + str(dict_has(d, "a"))
print "dict_has(d, 'c'): " + str(dict_has(d, "c"))
print "dict_has({}, 'a'): " + str(dict_has({}, "a"))

print "--- dict_keys ---"
var k = dict_keys(d)
print "len(dict_keys(d)): " + str(len(k))
print "k[0] == 'a' or k[0] == 'b': " + str(k[0] == "a" or k[0] == "b")
print "len(dict_keys({})): " + str(len(dict_keys({})))

print "--- dict_values ---"
var v = dict_values(d)
print "len(dict_values(d)): " + str(len(v))
print "v[0] == 10 or v[0] == 20: " + str(v[0] == 10 or v[0] == 20)
print "len(dict_values({})): " + str(len(dict_values({})))

print "--- Edge cases with non-dict / nil inputs ---"
print "dict_has(nil, 'a') == false: " + str(dict_has(nil, "a") == false)
print "dict_keys(nil) == []: " + str(dict_keys(nil) == [])
print "dict_values(nil) == []: " + str(dict_values(nil) == [])
print "dict_has(123, 'a') == false: " + str(dict_has(123, "a") == false)
