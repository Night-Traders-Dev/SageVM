print "--- Populated Dict Operations ---"
var d = {"a": 1, "b": 2}
print dict_has(d, "a")
print dict_has(d, "c")
print len(dict_keys(d))
print len(dict_values(d))

print "--- Empty Dict Operations ---"
var empty_d = {}
print dict_has(empty_d, "x")
print len(dict_keys(empty_d))
print len(dict_values(empty_d))

print "--- Edge & Invalid Inputs ---"
print dict_has(nil, "key")
print dict_has("not_a_dict", "key")
print dict_keys(nil)
print dict_keys(123)
print dict_values(nil)
print dict_values("string")
