# Test string methods
# BUG: These builtins are documented in docs/SPEC.md but are NOT currently
# implemented in src/svm/sgvm_vm.sage.

print "Upper:"
print upper("hello")
print "Lower:"
print lower("HELLO")

print "Strip:"
print strip("  hello  ")

print "Replace:"
print replace("hello world", "world", "sage")

print "Split:"
var parts = split("a,b,c", ",")
print type(parts)
print len(parts)

print "Join:"
print join(["a", "b", "c"], "-")
