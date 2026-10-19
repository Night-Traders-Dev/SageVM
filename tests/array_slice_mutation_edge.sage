print "--- 2D Matrix Slicing & Independence ---"
var matrix = [[1, 2], [3, 4], [5, 6]]
var sub = matrix[1:3]
print len(sub)
print sub[0][0]
print sub[1][0]

# Mutate top-level element in slice
sub[0] = [99, 100]
print sub[0][0]
print matrix[1][0]

print "--- Zero-Length & Empty Slices ---"
var zero_slice = matrix[1:1]
print len(zero_slice)

var empty_arr = []
var empty_slice = empty_arr[0:5]
print len(empty_slice)

print "--- Slice Builtin Boundary Values ---"
var arr = [10, 20, 30, 40, 50]
var s1 = slice(arr, 0, 10)
print len(s1)

var s2 = slice(arr, 3, 2)
print len(s2)

var s3 = slice(arr, -3, -1)
print len(s3)
