# Test dictionary built-ins
# BUG: dict_has, dict_keys, and dict_values are documented in docs/SPEC.md
# but are NOT currently implemented in src/svm/sgvm_vm.sage.
var d = {"a": 1, "b": 2}
# print "Dictionary: " + str(d) # host str() might return <dict>

print "Has 'a':"
print dict_has(d, "a")
print "Has 'c':"
print dict_has(d, "c")

var keys = dict_keys(d)
print "Keys type:"
print type(keys)

var values = dict_values(d)
print "Values type:"
print type(values)
