# Test string bracket indexing
# Normal behavior: retrieves character by zero-based index
# Edge cases: out-of-bounds index returns nil, negative indexing returns nil in SVM.
var s = "hello"
print s[0]
print s[1]
print s[4]
print s[-1]
print s[10]
print s[-10]
