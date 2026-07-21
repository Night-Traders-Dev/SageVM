# Test slice builtin function
# Normal behavior: slice(obj, start, end) creates a sub-collection slice.
# This is a builtin function that works on arrays and strings.
var a = [1, 2, 3, 4, 5]
var s = "hello"

print "Testing slice builtin on array:"
var a1 = slice(a, 1, 4)
print len(a1)
print a1[0]
print a1[1]
print a1[2]

print "Testing slice builtin on string:"
var s1 = slice(s, 1, 4)
print s1
