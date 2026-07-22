# Test the slice builtin function on strings and arrays
var a = [10, 20, 30, 40, 50]
var s = "abcdef"

print "Testing slice builtin on array:"
var a_slice = slice(a, 1, 4)
print len(a_slice)
print a_slice[0]
print a_slice[1]
print a_slice[2]

print "Testing slice builtin on string:"
var s_slice = slice(s, 1, 4)
# Note: String slice in SVM might return nil due to the float-to-int conversion issue,
# as noted in slice_test.sage. We will capture and document this.
print s_slice

print "Edge Case: Slice with out-of-bounds start/end:"
var a_oob = slice(a, 0, 10)
print len(a_oob)
